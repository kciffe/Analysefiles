import asyncio
from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from src.service.requirement_jobs import (
    create_requirement_job,
    get_requirement_job,
    pop_requirement_job_pending_answer,
    set_requirement_job_pending_answer,
)
from src.worker.requirement_worker import iter_requirement_job_events, iter_resume_requirement_job_events

from ..schemas import ResponseModel
from .schemas import (
    RequirementParseRecived,
    RequirementParseRequest,
    RequirementParseResponse,
    RequirementParseResultQueryResponse,
    RequirementClarifyRequest,
)

router = APIRouter()

_STATUS_TO_API = {
    "received": "已发布",
    "processing": "运行中",
    "success": "已完成",
    "failed": "已失败",
    "clarifying": "待澄清",
}


def _format_sse(event: str, data: str) -> str:
    return f"event: {event}\ndata: {data}\n\n"


def _sse_json(event: str, *, msg: str, data) -> str:
    payload = ResponseModel(
        code=200,
        msg=msg,
        data=data,
    )
    return _format_sse(event, payload.model_dump_json())


def _build_result_payload(job: dict) -> RequirementParseResultQueryResponse:
    status = str(job["status"])
    result = job.get("result") or None
    result_payload = RequirementParseResponse.model_validate(result) if result else None
    return RequirementParseResultQueryResponse(
        waiting=status in {"received", "processing", "clarifying"},
        id=job["id"],
        name=job["name"],
        status=_STATUS_TO_API.get(status, "已失败"),
        createdAt=job["createdAt"],
        result=result_payload,
        error=job.get("error"),
        clarificationQuestion=job.get("clarificationQuestion")or None,
        messages=job.get("messages")or[],
    )


def _stream_worker_events(events, *, msg: str):
    for event in events:
        yield _sse_json(
            str(event.get("event", "progress")),
            msg=msg,
            data=event.get("data", {}),
        )


async def _stream_job_state(item_id: str):
    last = ""
    while True:
        current = get_requirement_job(item_id)
        if current is None:
            break

        status = str(current["status"])
        if status == "clarifying":
            yield _sse_json(
                "requirement_clarification",
                msg="需要用户澄清",
                data={
                    "id": item_id,
                    "question": current.get("clarificationQuestion"),
                    "messages": current.get("messages") or [],
                },
            )
            break

        if status != last:
            yield _sse_json(
                "state",
                msg="收到后端响应，任务状态发生变化了。",
                data=_build_result_payload(current),
            )
            last = status

        if status in {"success", "failed", "clarifying"}:
            break
        await asyncio.sleep(0.5)


async def _stream_job_events(item_id: str):
    job = get_requirement_job(item_id)
    if job is None:
        return

    status = str(job["status"])
    if status == "received":
        req_data = job.get("requirementData") or {}
        for event in _stream_worker_events(
            iter_requirement_job_events(item_id, req_data),
            msg="需求解析，收到后端响应",
        ):
            yield event
    elif status == "processing" and job.get("pendingClarificationAnswer"):
        answer = pop_requirement_job_pending_answer(item_id)
        if answer is not None:
            for event in _stream_worker_events(
                iter_resume_requirement_job_events(item_id, answer),
                msg="需求澄清回复后继续执行",
            ):
                yield event
    else:
        async for event in _stream_job_state(item_id):
            yield event

    final_job = get_requirement_job(item_id)
    if final_job is not None:
        yield _sse_json(
            "result",
            msg="收到后端响应",
            data=_build_result_payload(final_job),
        )

    yield _format_sse("done", '{"ok": true}')


@router.post("/parse", response_model=ResponseModel[RequirementParseRecived])
async def submit_requirement_parse(
    payload: RequirementParseRequest,
) -> ResponseModel[RequirementParseRecived]:
    item_id = uuid4().hex # 后续这里需要明确设计一下
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
async def stream_requirement_progress(item_id: str) -> StreamingResponse:
    job = get_requirement_job(item_id)
    if job is None:
        raise HTTPException(status_code=404, detail="任务不存在")

    async def event_stream():
        async for event in _stream_job_events(item_id):
            yield event

    return StreamingResponse(
        event_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )

@router.post("/{item_id}/messages", response_model=ResponseModel[dict])
async def send_requirement_message(
    item_id: str,
    payload: RequirementClarifyRequest
) -> ResponseModel[dict]:
    job = get_requirement_job(item_id)
    if job is None:
        raise HTTPException(status_code=404, detail="任务不存在")

    if job["status"] != "clarifying":
        raise HTTPException(status_code=400, detail="任务不处于待澄清状态.")
    
    set_requirement_job_pending_answer(item_id, payload.answer)
    return ResponseModel(
        code=200,
        msg="需求明确窗口，已提交用户回复",
        data={
            "id": item_id,
            "need_clarification": False,
            "pending": True,
        },)

@router.get("/{item_id}/result",response_model=ResponseModel[RequirementParseResultQueryResponse])
async def query_requirement_result(
    item_id: str,
) -> ResponseModel[RequirementParseResultQueryResponse]:
    job = get_requirement_job(item_id)
    if job is None:
        raise HTTPException(status_code=404, detail="任务不存在")


    return ResponseModel(
        code=200,
        msg="需求解析结果查询成功",
        data=_build_result_payload(job),
    )
