from datetime import datetime, timezone
from uuid import uuid4
from datetime import datetime

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
    return f"event: {event}\\ndata: {data}\\n\\n"


def _build_result_payload(job: dict) -> RequirementParseResultQueryResponse:
    internal_status = str(job["status"])
    is_waiting = internal_status in {"received", "processing"}

    result = job.get("result")
    if isinstance(result, dict):
        result.setdefault("reportMarkdown", "")
    result_payload = (
        RequirementParseResponse.model_validate(result) if result is not None else None
    )

    return RequirementParseResultQueryResponse(
        waiting=is_waiting,
        id=job["id"],
        name=job["name"],
        status=_STATUS_TO_API.get(internal_status, "已失败"),
        createdAt=job["createdAt"],
        result=result_payload,
        error=job.get("error"),
    )


@router.post("/parse")
def submit_requirement_parse(payload: RequirementParseRequest) -> StreamingResponse:
    item_id =f"datetime.now().strftime('%Y-%m-%d_%H-%M-%S')-{uuid4().hex}"
    created_at = datetime.now(timezone.utc).isoformat()
    requirement_data = payload.model_dump(mode="json")

    create_requirement_job(
        item_id=item_id,
        name=payload.name,
        created_at=created_at,
        requirement_data=requirement_data,
    )

    def event_stream():
        received_payload = ResponseModel(
            code=200,
            msg="成功提交需求解析任务",
            data=RequirementParseRecived(
                id=item_id,
                name=payload.name,
                status="已发布",
                createdAt=created_at,
            ),
        )
        # 先立刻发第一条事件，告诉前端“任务已创建，连接正常”。
        yield _format_sse("received", received_payload.model_dump_json())

        for event in iter_requirement_job_events(item_id, requirement_data):
            event_name = str(event.get("event", "progress"))
            event_data = event.get("data", {})
            event_payload = ResponseModel[dict](
                code=200,
                msg="收到后端响应",
                data=event_data,
            )
            yield _format_sse(event_name, event_payload.model_dump_json())

        final_job = get_requirement_job(item_id)
        if final_job is not None:
            final_payload = ResponseModel(
                code=200,
                msg="收到后端响应",
                data=_build_result_payload(final_job),
            )
            yield _format_sse("result", final_payload.model_dump_json())

        yield _format_sse("done", '{"ok": true}')
    # 把整个 event_stream() 作为 HTTP 流返回
    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",    # 告诉浏览器不要缓存
            "Connection": "keep-alive",     # 告诉浏览器长连接
            "X-Accel-Buffering": "no",      # 告诉 Nginx 不缓存这个响应
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
