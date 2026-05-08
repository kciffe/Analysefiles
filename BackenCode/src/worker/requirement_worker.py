from datetime import date, datetime
from typing import Iterator
from langgraph.types import Command

from ..schemas.requirement_type import RequirementParseRequest, SearchDocumentsRequest
from ..workflow.requirement import  stream_requirement_graph
from ..workflow.requirement.state import ParseWorkFlowState
from ..utils import log_error,log_info,log_success,log_warning
from src.service.requirement_jobs import (
    get_requirement_job,
    set_requirement_job_failed,
    set_requirement_job_processing,
    set_requirement_job_success,
    set_requirement_job_clarifying,
    append_requirement_job_message,
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
            "interrupt_payload": None,
            
            "research_brief": None,
            "need_clarification": False,
            "clarification_question": None,

            "requirement": requirement_parse_request.detail,
            "task_name": item_id,     # 这个后续需要持久化到数据库中
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

# 取得中断时需要提供给用户的问题
def extract_interrupt_question(update: dict):
    res= update['__interrupt__'][0].value['question']
    return res
def iter_requirement_job_events(
    item_id: str, requirement_data: RequirementParseRequest
) -> Iterator[dict]:
    # 先检查任务是否存在，不存在就产出 failed 事件并结束。
    job = get_requirement_job(item_id)
    if job is None:
        log_error(f"需求任务不存在: {item_id}")
        yield {
            "event": "failed",
            "data": {"id": item_id, "error": "需求目标不存在"},
        }
        return

    # 设置任务为 processing 状态
    set_requirement_job_processing(item_id)
    log_info(f"需求任务开始执行: {item_id}")
    yield {"event": "processing", "data": {"id": item_id, "step": "started"}}

    # 构建初始 state。
    initial_state = build_initial_state(item_id, requirement_data)

    main_config={
        "configurable":{"thread_id":item_id}
    }
    try:
        # stream_requirement_graph(...) 跑图，拿到每个节点更新时产出 progress（含 node/step）。
        updates_iter = stream_requirement_graph(initial_state,main_config)
        final_state: ParseWorkFlowState | None = None


        for update in updates_iter:
            if "__interrupt__" in update:
                question=extract_interrupt_question(update)
                set_requirement_job_clarifying(item_id, question)
                log_warning(f"需求任务等待澄清: {item_id}")
                # 记录 对话历史，ass的内容
                append_requirement_job_message(item_id, "assistant", question)
                yield{
                    "event":"requirement_clarification",
                    "data": {"id": item_id, "question": question}
                }
                return 

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

        result = {
            "success": True,
            "reportMarkdown": final_state.get("report_markdown"),
        }
        set_requirement_job_success(item_id, result=result)
        log_success(f"需求任务执行完成: {item_id}")
        yield {"event": "success", "data": {"id": item_id, "result": result}}
    except Exception as exc:
        set_requirement_job_failed(item_id, error=str(exc))
        log_error(f"需求任务执行失败: {item_id}, error={exc}")
        yield {"event": "failed", "data": {"id": item_id, "error": str(exc)}}

    
def resume_requirement_job(item_id: str,answer:str):
    job = get_requirement_job(item_id)
    if job is None:
        log_error(f"需求任务不存在，无法恢复: {item_id}")
        return {"id": item_id, "error": "任务不存在","ok": False}
    
    main_config={ "configurable":{"thread_id":item_id} }

    append_requirement_job_message(item_id, "user", answer)
    set_requirement_job_processing(item_id)
    log_info(f"需求任务收到澄清回复并恢复执行: {item_id}")

    final_state = None

    for update in stream_requirement_graph(Command(resume=answer),main_config):
        # 再次触发中断
        if "__interrupt__" in update:
            question=extract_interrupt_question(update)
            set_requirement_job_clarifying(item_id, question)
            log_warning(f"需求任务再次等待澄清: {item_id}")
            # 记录 对话历史，ass的内容
            append_requirement_job_message(item_id, "assistant", question)
            return{
                "id":item_id,
                "need_clarification":True,
                "question":question,
            }
        # 若未继续触发中断，final_state增量更新
        for _,node_delta in update.items():
            final_state={**(final_state or {}),**node_delta}

    result={
        "success":True,
        "reportMarkdown":final_state.get("report_markdown")if final_state else None,
    }
    set_requirement_job_success(item_id,result=result)
    log_success(f"需求任务恢复后执行完成: {item_id}")
    return {
        "id":item_id,
        "need_clarification":False,
        "result":result,
    }
    
