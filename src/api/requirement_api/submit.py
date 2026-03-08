from fastapi import APIRouter, HTTPException

from src.service.requirement_parse import analyze_requirement
from .schemas import RequirementParseRequest, RequirementParseResponse

router = APIRouter()


@router.post("/parse", response_model=RequirementParseResponse)
async def submit_requirement_parse(
    payload: RequirementParseRequest,
) -> RequirementParseResponse:
    try:
        result = analyze_requirement(payload.model_dump(mode="json"))
        return RequirementParseResponse.model_validate(result)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Requirement analysis failed: {exc}",
        ) from exc
