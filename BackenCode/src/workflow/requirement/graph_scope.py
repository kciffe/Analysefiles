
from pathlib import Path

from langgraph.graph import StateGraph, END, START
from src.workflow.requirement.node_scope import clarify_with_user, write_research_brief
from src.workflow.requirement.state_scope import AgentInputState, AgentState

requirement_scope_builder=StateGraph(AgentState,input_schema=AgentInputState)
requirement_scope_builder.add_node("clarify_with_user", clarify_with_user)
requirement_scope_builder.add_node("write_research_brief", write_research_brief)

requirement_scope_builder.add_edge(START,"clarify_with_user")
requirement_scope_builder.add_edge("write_research_brief",END)

requirement_scope_graph=requirement_scope_builder.compile()


from langgraph.checkpoint.memory import InMemorySaver

checkpointer = InMemorySaver()
scope = requirement_scope_builder.compile(checkpointer=checkpointer)
graph_png = scope.get_graph(xray=True).draw_mermaid_png()
graph_png_path = Path(__file__).with_suffix(".png")
graph_png_path.write_bytes(graph_png)
print(f"执行流程图保存到: {graph_png_path}")
