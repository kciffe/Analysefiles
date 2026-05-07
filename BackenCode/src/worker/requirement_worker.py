from datetime import date, datetime
from typing import Iterator

from ..schemas.requirement_type import RequirementParseRequest, SearchDocumentsRequest
from ..workflow.requirement import run_requirement_graph, stream_requirement_graph
from ..workflow.requirement.state import ParseWorkFlowState
from src.service.requirement_jobs import (
    get_requirement_job,
    set_requirement_job_failed,
    set_requirement_job_processing,
    set_requirement_job_success,
)


def _to_ymd(value):
    if isinstance(value, datetime):
        return value.strftime("%Y-%m-%d")
    if isinstance(value, date):
        return value.strftime("%Y-%m-%d")
    return value


def build_initial_state(
    item_id: str, requirement_parse_request: RequirementParseRequest
) -> ParseWorkFlowState:
    if isinstance(requirement_parse_request, dict):
        requirement_parse_request = RequirementParseRequest(**requirement_parse_request)

    request = SearchDocumentsRequest(
        keywords=requirement_parse_request.keywords,
        doc_types=requirement_parse_request.docTypes,
        start_date=_to_ymd(requirement_parse_request.startDate),
        end_date=_to_ymd(requirement_parse_request.endDate),
        limit=128,
    )

    return ParseWorkFlowState(
        {
            "messages": [],
            "tool_traces":[],

            # "research_brief": None,
            # "need_clarification": False,
            # "clarification_question": None,

            "requirement": requirement_parse_request.detail,
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
        }
    )


def iter_requirement_job_events(
    item_id: str, requirement_data: RequirementParseRequest
) -> Iterator[dict]:
    # 先检查任务是否存在，不存在就产出 failed 事件并结束。
    job = get_requirement_job(item_id)
    if job is None:
        yield {
            "event": "failed",
            "data": {"id": item_id, "error": "需求目标不存在"},
        }
        return

    # 设置任务为 processing 状态
    set_requirement_job_processing(item_id)
    yield {"event": "processing", "data": {"id": item_id, "step": "started"}}

    # 构建初始 state。
    initial_state = build_initial_state(item_id, requirement_data)

    try:
        # stream_requirement_graph(...) 跑图，拿到每个节点更新时产出 progress（含 node/step）。
        updates_iter = stream_requirement_graph(initial_state)
        final_state: ParseWorkFlowState | None = None

        for update in updates_iter:
            for node_name, node_delta in update.items():
                step = node_delta.get("current_step") or node_name
                final_state = {**(final_state or {}), **node_delta}
                yield {
                    "event": "progress",
                    "data": {
                        "id": item_id,
                        "node": node_name,
                        "step": step,
                    },
                }

        if final_state is None:
            final_state = run_requirement_graph(initial_state)

        result = {
            "success": True,
            "reportMarkdown": final_state.get("report_markdown"),
        }
        set_requirement_job_success(item_id, result=result)
        yield {"event": "success", "data": {"id": item_id, "result": result}}
    except Exception as exc:
        set_requirement_job_failed(item_id, error=str(exc))
        yield {"event": "failed", "data": {"id": item_id, "error": str(exc)}}


def run_requirement_job(item_id: str, requirement_data: RequirementParseRequest):
    job = get_requirement_job(item_id)
    if job is None:
        return None

    set_requirement_job_processing(item_id)
    initial_state = build_initial_state(item_id, requirement_data)

    try:
        final_state = run_requirement_graph(initial_state)
        set_requirement_job_success(
            item_id,
            result={
                "success": True,
                "reportMarkdown": final_state.get("report_markdown"),
            },
        )
        return final_state
    except Exception as exc:
        set_requirement_job_failed(item_id, error=str(exc))
        raise ValueError(f"job出错 item_id: {item_id}, error: {str(exc)}")
