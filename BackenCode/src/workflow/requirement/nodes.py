import json
from datetime import datetime, date
from uuid import uuid4

from langchain_core.messages import AIMessage, ToolMessage

from .state import ParseWorkFlowState
from ...agent.requirement.report_generator import generate_report_agent
from ...agent.requirement import generate_report_plans_agent
from ...agent.requirement.prompt import _GENERATE_REPORT_PROMPT
from ...agent.requirement import generate_evidence_agent

def prepare_query_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : prepare_query_node")
    return {
        "current_step": "prepare_query_node"
    }


# 检索文档节点，调用工具函数 search_documents 进行检索，返回结果存储在 workflow_state.candidate_documents 中。
def retrieval_documents_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : retrieval_documents_node")
    req = workflow_state["search_document_request"]
    return {
        "messages": [
            AIMessage(
                content=f"执行检索相关文档节点，当前关键词：{req.keywords}",
                tool_calls=[
                    {
                        "id": f"call_retrieval_documents_node_{uuid4().hex}",
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
        ],
        "current_step": "retrieval_documents_node",
    }

# 收集检索结果节点，从 messages 中找到最新的 search_documents 工具调用结果，并将文档列表存储在 workflow_state.candidate_documents 中。
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

    print(f"⚠️  检索到的候选文档：{docs}")
    return {
        "candidate_documents": docs,
        "current_step": "collect_retrieval_results_node",
    }
# 分析需要哪些段落，并写出为啥需要阅读这些段落，生成 ReTrievalPlan “检索计划”列表，存储在 workflow_state.retrieval_plan 中。
def generate_evidence_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : generate_evidence_node")
    return {
        "retrieval_plan": generate_evidence_agent(workflow_state),
        "current_step": "generate_evidence_node"
    }

# 依据证据和所需要的段落调用工具检索，只发起调用工具
def read_sections_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : read_sections_node")
    plans = workflow_state.get("retrieval_plan") or []
    if not plans:
        print("⚠️  retrieval_plan 为空，当前不会发起任何段落检索调用")

    tool_calls=[]
    pending_read_map = {}

    for plan in plans:
        doc_id = plan.doc_id
        section_title = plan.section_title
        why_read = plan.why_read
        tool_id = f"call_read_sections_node_{datetime.now()}_{uuid4().hex}"
        pending_read_map[tool_id] = {
            "doc_id": doc_id,
            "section_title": section_title,
            "why_read": why_read,
        }
        
        tool_calls.append(
            {
                "id": tool_id,
                "name": "search_paragraph",
                "args": {
                    "doc_id": doc_id,
                    "section_title": section_title,
                },

            }
        )
    print(f"ℹ️  准备调用 search_paragraph: plans={len(plans)}, tool_calls={len(tool_calls)}")
    return {
        "messages": [
            AIMessage(
                content=(
                    f"执行段落检索，共 {len(tool_calls)} 个章节"
                ),
                tool_calls=tool_calls
            )
        ],
        "pending_read_map": pending_read_map,
        "current_step": "read_sections_node",
    }
#  收集段落检索结果
def collect_read_sections_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : collect_read_sections_node")
    pending = workflow_state.get("pending_read_map", {})
    out = []

    for msg in workflow_state.get("messages", []):
        if getattr(msg, "name", None) != "search_paragraph":
            continue

        meta = pending.get(getattr(msg, "tool_call_id", None))
        if not meta:
            continue

        try:
            data = json.loads(msg.content) if isinstance(msg.content, str) else msg.content
        except Exception:
            continue

        if data.get("error"):
            print(f"❌ 段落检索失败: {data.get('error')}")
            continue
        text = data.get("text")
        if not text:
            continue

        out.append({
            "evidence": meta.get("why_read", ""),  # 之前生成的 why_read
            "section": text,               # 检索出来的段落
        })
        print(f"⚠️  检索到的段落：{text[:120]}，对应的证据需求是：{meta.get('why_read', '')}")
    
    print(f"ℹ️  read_sections 汇总: ok={len(out)}")
    return {
        "already_read_sections": out,
        "current_step": "collect_read_sections_node",
    }

        




def generate_report_node(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n✅ 进入 : generate_report_node")
    print(f"ℹ️  生成报告输入证据条数: {len(workflow_state.get('already_read_sections') or [])}")
    prompt = _GENERATE_REPORT_PROMPT.format(
        requirement=workflow_state["requirement"],
        already_read_sections=workflow_state["already_read_sections"],
    )
    return {
        "current_step": "generate_report_node",
        "report_markdown": generate_report_agent(prompt=prompt),
    }
