from .graph import requirement_graph
from .state import ParseWorkFlowState
def run_requirement_graph(workflow_state:ParseWorkFlowState)->ParseWorkFlowState:
    # final_state=None
    # for idx,event in enumerate(requirement_graph.stream(workflow_state),start=1):
    #     print(f"\n[STEP {idx}]")
    #     print(f"event: {event}")
    #     final_state=event
    # return final_state

    return requirement_graph.invoke(workflow_state)

