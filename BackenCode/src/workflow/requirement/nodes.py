import json
from uuid import uuid4

from langchain_core.messages import AIMessage, ToolMessage

from .state import ParseWorkFlowState
from ...agent.report_generator import generate_report_agent
from ...agent import generate_report_plans_agent
from .prompt import _GENERATE_REPORT_PROMPT, _GENERATE_PLANS_PROMPT


def prepare_query_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : prepare_query_node")
    workflow_state["current_step"] = "prepare_query_node"
    return workflow_state


def retrieval_documents_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : retrieval_documents_node")
    req = workflow_state["search_document_request"]
    return {
        "messages": [
            AIMessage(
                content=f"执行检索相关文档节点，当前关键词：{req.keywords}",
                tool_calls=[
                    {
                        "id": f"call_{uuid4().hex}",
                        "name": "search_documents",
                        "args": {
                            "keywords": req.keywords,
                            "doc_types": req.doc_types,
                            "start_date": req.start_date,
                            "end_date": req.end_date,
                            "limit": req.limit,
                        },
                    }
                ],
            )
        ]
    }


def collect_retrieval_results_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : collect_retrieval_results_node")
    messages = workflow_state.get("messages", [])
    docs = []

    # Find the latest ToolMessage from search_documents.
    for msg in reversed(messages):
        if not isinstance(msg, ToolMessage):
            continue
        if getattr(msg, "name", None) != "search_documents":
            continue

        content = msg.content
        parsed = json.loads(content) if isinstance(content, str) else content

        if isinstance(parsed, list):
            docs = parsed
        elif isinstance(parsed, dict) and isinstance(parsed.get("data"), list):
            docs = parsed["data"]
        break

    workflow_state["candidate_documents"] = docs
    workflow_state["current_step"] = "collect_retrieval_results_node"
    return workflow_state


def generate_plans_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : generate_plans_node")
    workflow_state["plans"] = generate_report_plans_agent(
        prompt=_GENERATE_PLANS_PROMPT.format(requirement=workflow_state["requirement"])
    )
    workflow_state["current_step"] = "generate_plans_node"
    return workflow_state


def read_sections_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : read_sections_node")
    return {
        "messages": [
            AIMessage(
                content=(
                    f"执行阅读文档相关章节节点，当前选中文档：{workflow_state['candidate_documents']}，"
                    f"当前计划：{workflow_state['plans']}"
                ),
                tool_calls=[
                    {
                        "id": f"call_{uuid4().hex}",
                        "name": "search_paragraph",
                        "args": {},
                    }
                ],
            )
        ]
    }


def judge_evidence_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : judge_evidence_node")
    workflow_state["evidence_sufficient"] = len(workflow_state.get("plans") or []) == 0
    workflow_state["current_step"] = "judge_evidence"
    return workflow_state


def refine_keywords_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : refine_keywords_node")
    workflow_state["current_keywords"] = []
    workflow_state["current_step"] = "refine_keywords_node"
    return workflow_state


def generate_report_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : generate_report_node")
    prompt = _GENERATE_REPORT_PROMPT.format(
        requirement=workflow_state["requirement"],
        already_read_sections=workflow_state["already_read_sections"],
    )
    workflow_state["report_markdown"] = generate_report_agent(prompt=prompt)
    return workflow_state
