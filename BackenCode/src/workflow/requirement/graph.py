from .state import ParseWorkFlowState
from .nodes import *
from ...tools import TOOLS
from .graph_scope import requirement_scope_graph
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from langgraph.checkpoint.memory import InMemorySaver
from typing_extensions import Literal



def router_after_tools(workflow_state: ParseWorkFlowState) -> Literal["collect_retrieval_results","collect_read_sections_results"]:
    if workflow_state.get("current_step") == "retrieval_documents_node":
        return "collect_retrieval_results"
    return "collect_read_sections_results"


def build_requirement_graph():
    builder = StateGraph(ParseWorkFlowState)

    tool_node = ToolNode(TOOLS)

    builder.add_node("tools", tool_node)
    builder.add_node("prepare_scope_input_node",prepare_scope_input_node)
    builder.add_node("requirement_scope_graph",requirement_scope_graph)
    builder.add_node("apply_scope_output_node",apply_scope_output_node)
    # builder.add_node("convert_to_scope", convert_to_scope_node)
    builder.add_node("retrieval_documents", retrieval_documents_node)
    builder.add_node("collect_retrieval_results", collect_retrieval_results_node)
    builder.add_node("generate_evidence", generate_evidence_node)
    builder.add_node("read_sections", read_sections_node)
    builder.add_node("collect_read_sections_results", collect_read_sections_node)
    builder.add_node("generate_report", generate_report_node)

    builder.set_entry_point("prepare_scope_input_node")

    builder.add_edge("prepare_scope_input_node", "requirement_scope_graph")
    builder.add_edge("requirement_scope_graph", "apply_scope_output_node")
    builder.add_edge("apply_scope_output_node", "retrieval_documents")
    builder.add_edge("retrieval_documents", "tools")
    builder.add_edge("collect_retrieval_results", "generate_evidence")
    builder.add_edge("generate_evidence", "read_sections")
    builder.add_edge("read_sections", "tools")
    builder.add_edge("collect_read_sections_results", "generate_report")

    builder.add_conditional_edges("tools", router_after_tools)

    builder.add_edge("generate_report", END)

    main_checkpointer = InMemorySaver()
    return builder.compile(checkpointer=main_checkpointer)


requirement_graph = build_requirement_graph()
