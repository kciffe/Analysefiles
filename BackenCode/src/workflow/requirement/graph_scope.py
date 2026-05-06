from pathlib import Path

from langgraph.checkpoint.memory import InMemorySaver
from langgraph.graph import END, START, StateGraph

from src.utils.logger import log_success
from src.workflow.requirement.node_scope import clarify_with_user, write_research_brief
from src.workflow.requirement.state_scope import AgentInputState, AgentState


requirement_scope_builder = StateGraph(AgentState, input_schema=AgentInputState)
requirement_scope_builder.add_node("clarify_with_user", clarify_with_user)
requirement_scope_builder.add_node("write_research_brief", write_research_brief)

requirement_scope_builder.add_edge(START, "clarify_with_user")
requirement_scope_builder.add_edge("write_research_brief", END)

requirement_scope_graph = requirement_scope_builder.compile()

checkpointer = InMemorySaver()
scope = requirement_scope_builder.compile(checkpointer=checkpointer)
graph_png = scope.get_graph(xray=True).draw_mermaid_png()
graph_png_path = Path(__file__).with_suffix(".png")
graph_png_path.write_bytes(graph_png)
log_success(f"Graph image saved to: {graph_png_path}")
