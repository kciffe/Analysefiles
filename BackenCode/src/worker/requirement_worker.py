from datetime import date, datetime
from ..schemas.requirement_type import SearchDocumentsRequest,RequirementParseRequest
from ..workflow.requirement.state import ParseWorkFlowState
from src.service.requirement_jobs import (
    get_requirement_job,
    set_requirement_job_processing,
    set_requirement_job_success,
    set_requirement_job_failed,
)

from ..workflow.requirement import run_requirement_graph

def _to_ymd(value):
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d")
    if isinstance(value, date):
        return value.strftime("%Y-%m-%d")
    return value

def build_initial_state(item_id: str, requirement_parse_request: RequirementParseRequest) -> ParseWorkFlowState:
    request = SearchDocumentsRequest(
        keywords=requirement_parse_request.keywords,
        doc_types=requirement_parse_request.docTypes,
        start_date=_to_ymd(requirement_parse_request.startDate),
        end_date=_to_ymd(requirement_parse_request.endDate),
        limit=128,
    )

    return ParseWorkFlowState({
        "messages": [],
        "requirement": requirement_parse_request.detail or "",
        "task_name": requirement_parse_request.name or item_id,
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
def run_requirement_job(item_id: str,requirement_data: RequirementParseRequest):

    job = get_requirement_job(item_id)
    if job is None:
        return

    set_requirement_job_processing(item_id)
    
    inital_state=build_initial_state(item_id, requirement_data)

    try:
        final_state = run_requirement_graph(inital_state)
        set_requirement_job_success(
            item_id,
            result={
                "success": True,
                "reportMarkdown": final_state.get("report_markdown"),
            },
        )
    except Exception as e:
        set_requirement_job_failed(
            item_id,
            error=str(e),
        )
        raise ValueError(f"job出错 item_id: {item_id}, error: {str(e)}") 

