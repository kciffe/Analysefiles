from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, BackgroundTasks, HTTPException, Response
from ..schemas import ResponseModel
from src.service.requirement_jobs import (
    create_requirement_job,
    get_requirement_job,
    set_requirement_job_failed,
    set_requirement_job_processing,
    set_requirement_job_success,
)
from src.service.requirement_parse import analyze_requirement
from .schemas import (
    RequirementParseRecived,
    RequirementParseRequest,
    RequirementParseResponse,
    RequirementParseResultQueryResponse,
)

router = APIRouter()


@router.post("/parse", response_model=ResponseModel[RequirementParseRecived])
async def submit_requirement_parse(
    background_tasks: BackgroundTasks,
    payload: RequirementParseRequest,
) -> ResponseModel:
    item_id = uuid4().hex
    created_at = datetime.now(timezone.utc).isoformat()
    requirement_data = payload.model_dump(mode="json")

    create_requirement_job(
        item_id=item_id,
        name=payload.name,
        created_at=created_at,
        requirement_data=requirement_data,
    )

    background_tasks.add_task(
        _run_requirement_analysis,
        item_id,
    )

    return ResponseModel(
        code=200,
        msg="成功提交需求解析任务",
        data= RequirementParseRecived(
            id=item_id,
            name=payload.name,
            status="运行中",
            createdAt=created_at,
        )
    )



@router.get("/{item_id}/result", response_model=RequirementParseResultQueryResponse)
async def query_requirement_result(
    item_id: str,
    response: Response,
) -> RequirementParseResultQueryResponse:
    job = get_requirement_job(item_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Requirement item not found.")

    status = job["status"]
    if status in {"received", "processing"}:
        response.status_code = 202

    result = job.get("result")
    result_payload = (
        RequirementParseResponse.model_validate(result) if result is not None else None
    )

    return RequirementParseResultQueryResponse(
        id=job["id"],
        name=job["name"],
        status=status,
        createdAt=job["createdAt"],
        result=result_payload,
        error=job.get("error"),
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
