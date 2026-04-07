from .graph import requirement_graph
from .state import ParseWorkFlowState


def run_requirement_graph(workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    return requirement_graph.invoke(workflow_state)


def stream_requirement_graph(workflow_state: ParseWorkFlowState):
    return requirement_graph.stream(workflow_state, stream_mode="updates")
