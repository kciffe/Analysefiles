from .state import ParseWorkFlowState
from .nodes import *
from ...tools import TOOLS

from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode


def router_after_judge_evidence(workflow_state: ParseWorkFlowState) -> str:
    if workflow_state["evidence_sufficient"]:
        return "generate_report"
    return "read_sections"


def build_requirement_graph():
    builder = StateGraph(ParseWorkFlowState)

    tool_node = ToolNode(TOOLS)

    builder.add_node("tools", tool_node)
    builder.add_node("prepare_query", prepare_query_node)
    builder.add_node("retrieval_documents", retrieval_documents_node)
    builder.add_node("collect_retrieval_results", collect_retrieval_results_node)
    builder.add_node("read_sections", read_sections_node)
    builder.add_node("judge_evidence", judge_evidence_node)
    builder.add_node("generate_report", generate_report_node)

    builder.set_entry_point("prepare_query")

    builder.add_edge("prepare_query", "retrieval_documents")
    builder.add_edge("retrieval_documents", "tools")
    builder.add_edge("tools", "collect_retrieval_results")
    builder.add_edge("collect_retrieval_results", "read_sections")
    builder.add_edge("read_sections", "judge_evidence")

    builder.add_conditional_edges("judge_evidence", router_after_judge_evidence)

    builder.add_edge("generate_report", END)

    return builder.compile()


requirement_graph = build_requirement_graph()
