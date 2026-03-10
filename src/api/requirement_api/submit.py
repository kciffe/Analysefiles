from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, BackgroundTasks

from src.service.requirement_parse import analyze_requirement
from .schemas import RequirementParseRecived, RequirementParseRequest

router = APIRouter()


@router.post("/parse", response_model=RequirementParseRecived)
async def submit_requirement_parse(
    background_tasks: BackgroundTasks,
    payload: RequirementParseRequest,
) -> RequirementParseRecived:
    item_id = uuid4().hex
    created_at = datetime.now(timezone.utc).isoformat()

    background_tasks.add_task(
        _run_requirement_analysis,
        payload.model_dump(mode="json"),
    )

    return RequirementParseRecived(
        id=item_id,
        name=payload.name,
        status="received",
        createdAt=created_at,
    )


def _run_requirement_analysis(requirement_data: dict) -> None:
    try:
        analyze_requirement(requirement_data)
    except Exception as exc:
        # Minimal demo: errors are logged only.
        print(f"[requirement-analysis] failed: {exc}")
