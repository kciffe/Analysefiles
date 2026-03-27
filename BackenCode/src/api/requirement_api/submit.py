from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, BackgroundTasks, HTTPException
from src.agent.base import Agent

from src.service.requirement_jobs import (
    create_requirement_job,
    get_requirement_job,
    set_requirement_job_failed,
    set_requirement_job_processing,
    set_requirement_job_success,
)
from src.service.requirement_parse import analyze_requirement

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


@router.post("/parse", response_model=ResponseModel[RequirementParseRecived])
async def submit_requirement_parse(
    background_tasks: BackgroundTasks,
    payload: RequirementParseRequest,
) -> ResponseModel[RequirementParseRecived]:
    item_id = uuid4().hex
    created_at = datetime.now(timezone.utc).isoformat()
    requirement_data = payload.model_dump(mode="json")

    # 作用：创建任务记录，初始状态为 "received"，并将任务数据存储在内存中，以便后续处理函数访问和更新。
    create_requirement_job(
        item_id=item_id,
        name=payload.name,
        created_at=created_at,
        requirement_data=requirement_data,
    )

    flag = False
    agent = Agent()
    def generator_():
        if not flag:
            yield f"data: {ResponseModel(code=200, msg='成功提交需求解析任务', data=RequirementParseRecived(id=item_id, name=payload.name, status='已发布', createdAt=created_at)).model_dump_json()}\n\n"
            flag = True
        else:
            yield agent.run(payload)
    

    return StreamingResponse(generator_(), media_type="text/event-stream")

    #TODO:
    #做一个迭代器，满足SSE格式，返回的类型为stringmingresponse
    background_tasks.add_task(_run_requirement_analysis, item_id)

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

    internal_status = str(job["status"])
    is_waiting = internal_status in {"received", "processing"}

    result = job.get("result")
    result_payload = (
        RequirementParseResponse.model_validate(result) if result is not None else None
    )

    return ResponseModel(
        code=200,
        msg="收到后端响应",
        data=RequirementParseResultQueryResponse(
            waiting=is_waiting,
            id=job["id"],
            name=job["name"],
            status=_STATUS_TO_API.get(internal_status, "已失败"),
            createdAt=job["createdAt"],
            result=result_payload,
            error=job.get("error"),
        ),
    )


def _run_requirement_analysis(item_id: str) -> None:
    job = get_requirement_job(item_id)
    if job is None:
        return

    set_requirement_job_processing(item_id)
    requirement_data = job["requirementData"]

    try:
        result = analyze_requirement(requirement_data)
        validated = RequirementParseResponse.model_validate(result)
        set_requirement_job_success(
            item_id,
            result=validated.model_dump(mode="json"),
        )
    except Exception as exc:
        set_requirement_job_failed(item_id, error=str(exc))
