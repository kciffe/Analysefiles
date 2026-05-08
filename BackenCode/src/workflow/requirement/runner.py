from .graph import requirement_graph
from .state import ParseWorkFlowState

def run_requirement_graph(workflow_state: ParseWorkFlowState,config) -> ParseWorkFlowState:
    return requirement_graph.invoke(
        workflow_state,
        config=config
    )


def stream_requirement_graph(workflow_state: ParseWorkFlowState,config):
    return requirement_graph.stream(
        workflow_state, 
        config=config,
        stream_mode="updates")
