import time
from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from src.service.requirement_jobs import create_requirement_job, get_requirement_job
from src.worker.requirement_worker import iter_requirement_job_events

from ..schemas import ResponseModel
from .schemas import (
    RequirementParseRecived,
    RequirementParseRequest,
    RequirementParseResponse,
    RequirementParseResultQueryResponse,
)

router = APIRouter()

_STATUS_TO_API = {
    "received": "已发布",
    "processing": "运行中",
    "success": "已完成",
    "failed": "已失败",
}


def _format_sse(event: str, data: str) -> str:
    return f"event: {event}\ndata: {data}\n\n"


def _build_result_payload(job: dict) -> RequirementParseResultQueryResponse:
    status = str(job["status"])
    result = job.get("result") or None
    result_payload = RequirementParseResponse.model_validate(result) if result else None
    return RequirementParseResultQueryResponse(
        waiting=status in {"received", "processing"},
        id=job["id"],
        name=job["name"],
        status=_STATUS_TO_API.get(status, "已失败"),
        createdAt=job["createdAt"],
        result=result_payload,
        error=job.get("error"),
    )


@router.post("/parse", response_model=ResponseModel[RequirementParseRecived])
async def submit_requirement_parse(
    payload: RequirementParseRequest,
) -> ResponseModel[RequirementParseRecived]:
    item_id = uuid4().hex
    created_at = datetime.now(timezone.utc).isoformat()

    create_requirement_job(
        item_id=item_id,
        name=payload.name,
        created_at=created_at,
        requirement_data=payload.model_dump(mode="json"),
    )

    return ResponseModel(
        code=200,
        msg="成功提交需求解析任务",
        data=RequirementParseRecived(
            id=item_id,
            name=payload.name,
            status="已发布",
            createdAt=created_at,
        ),
    )


@router.get("/{item_id}/stream")
def stream_requirement_progress(item_id: str) -> StreamingResponse:
    job = get_requirement_job(item_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Requirement item not found.")

    def event_stream():
        job_snapshot = get_requirement_job(item_id)
        if job_snapshot is None:
            yield _format_sse("failed", '{"code":404,"msg":"Requirement item not found."}')
            yield _format_sse("done", '{"ok": false}')
            return

        status = str(job_snapshot["status"])
        if status == "received":
            req_data = job_snapshot.get("requirementData") or {}
            for event in iter_requirement_job_events(item_id, req_data):
                name = str(event.get("event", "progress"))
                payload = ResponseModel[dict](
                    code=200,
                    msg="收到后端响应",
                    data=event.get("data", {}),
                )
                yield _format_sse(name, payload.model_dump_json())
        else:
            last = ""
            while True:
                current = get_requirement_job(item_id)
                if current is None:
                    break
                now = str(current["status"])
                if now != last:
                    payload = ResponseModel(
                        code=200,
                        msg="收到后端响应",
                        data=_build_result_payload(current),
                    )
                    yield _format_sse("state", payload.model_dump_json())
                    last = now
                if now in {"success", "failed"}:
                    break
                time.sleep(0.5)

        final_job = get_requirement_job(item_id)
        if final_job is not None:
            payload = ResponseModel(
                code=200,
                msg="收到后端响应",
                data=_build_result_payload(final_job),
            )
            yield _format_sse("result", payload.model_dump_json())

        yield _format_sse("done", '{"ok": true}')

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


@router.get(
    "/{item_id}/result",
    response_model=ResponseModel[RequirementParseResultQueryResponse],
)
async def query_requirement_result(
    item_id: str,
) -> ResponseModel[RequirementParseResultQueryResponse]:
    job = get_requirement_job(item_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Requirement item not found.")

    return ResponseModel(
        code=200,
        msg="收到后端响应",
        data=_build_result_payload(job),
    )
