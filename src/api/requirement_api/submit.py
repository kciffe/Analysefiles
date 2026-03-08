from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter

from ..schemas import ResponseModel
from .schemas import RequirementParseRequest, RequirementSubmitResponse

router = APIRouter()


@router.post("/parse", response_model=ResponseModel[RequirementSubmitResponse])
async def submit_requirement_parse(
    payload: RequirementParseRequest,
) -> ResponseModel[RequirementSubmitResponse]:
    task_id = uuid4().hex

    return ResponseModel(
        code=200,
        data=RequirementSubmitResponse(
            id=task_id,
            name=payload.name,
            status="pending",
            createdAt=datetime.now(timezone.utc),
        ),
    )
