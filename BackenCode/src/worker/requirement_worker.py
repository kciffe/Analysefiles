from ..schemas.requirement_type import SearchDocumentsRequest,RequirementParseRequest
from ..workflow.requirement.state import ParseWorkFlowState
from src.service.requirement_jobs import (
    get_requirement_job,
    set_requirement_job_processing,
    set_requirement_job_success,
    set_requirement_job_failed,
)

from ..workflow.requirement import run_requirement_graph
def run_requirement_job(item_id: str,requirement_data: RequirementParseRequest):

    job = get_requirement_job(item_id)
    if job is None:
        return

    set_requirement_job_processing(item_id)
    
    inital_state=build_initial_state(item_id, requirement_data)

    try:
        run_requirement_graph(inital_state)
        set_requirement_job_success(item_id)

    except Exception as e:
        set_requirement_job_failed(
            item_id,
            error=str(e),
        )

def build_initial_state(item_id: str, payload_dict: dict) -> ParseWorkFlowState:
    request = SearchDocumentsRequest(
        keywords=payload_dict.get("keywords") or [],
        doc_types=payload_dict.get("docTypes"),
        start_date=payload_dict.get("startDate"),
        end_date=payload_dict.get("endDate"),
        limit=128,
    )

    return ParseWorkFlowState({
        "messages": [],
        "requirement": payload_dict.get("detail") or "",
        "task_name": payload_dict.get("name") or item_id,
        "search_document_request": request,
        "current_keywords": request.keywords or [],
        "retrieval_round": 0,
        "candidate_documents": [],
        "plans": None,
        "already_read_sections": [],
        "evidence_sufficient": False,
        "report_markdown": None,
        "current_step": "init",
        "status": "processing",
        "error_message": None,
    })