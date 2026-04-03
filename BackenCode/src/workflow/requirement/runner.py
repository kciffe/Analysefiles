from .graph import requirement_graph
from .state import ParseWorkFlowState
def run_requirement_graph(workflow_state:ParseWorkFlowState)->ParseWorkFlowState:
    last=None
    for event in requirement_graph.stream(workflow_state):
        last=event
    return last
