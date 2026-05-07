from pathlib import Path
import sys
from src.utils import format_messages
from src.utils import log_info, log_success
from langchain_core.messages import HumanMessage
# from ..workflow.requirement.graph_scope import scope
from ..workflow.requirement.graph import build_requirement_graph
scope = build_requirement_graph()
def save_graph_image() -> None:
    graph_png = scope.get_graph(xray=True).draw_mermaid_png()
    graph_png_path = Path(__file__).with_suffix(".png")
    graph_png_path.write_bytes(graph_png)
    log_success(f"Graph image saved to: {graph_png_path}")

def invoke_scope_graph(user_input: str, thread_id: str = "1") -> dict:
    thread = {"configurable": {"thread_id": thread_id}}
    return scope.invoke({"messages": [HumanMessage(content=user_input)]}, config=thread)

def main() -> None:
    save_graph_image()

    while False:
       
        user_input = " ".join(sys.argv[1:]).strip()
        if not user_input:
            user_input = input("输入需求: ").strip()

        if not user_input:
            log_info("未输入任何需求.")
            return

        result = invoke_scope_graph(user_input)
        log_success(format_messages(result["messages"]))


if __name__ == "__main__":
    main()