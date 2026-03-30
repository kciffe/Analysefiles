import os
import json
from langchain_core.messages import ToolMessage
from dotenv import load_dotenv
from langchain_core.tools import tool,InjectedToolCallId
from typing import Annotated
from typing_extensions import TypedDict
from langchain.chat_models import init_chat_model
from langchain_tavily import TavilySearch
from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langgraph.prebuilt import ToolNode,tools_condition
from langgraph.checkpoint.memory import MemorySaver
from langgraph.types import Command,interrupt


# =========================
# 1. 加载环境变量
# =========================
load_dotenv()
deepseek_api_key = os.getenv("DEEPSEEK_API_KEY")
tavily_api_key = os.getenv("TAVILY_API_KEY")

# =========================
# 2. 初始化模型
# =========================
llm = init_chat_model("deepseek-chat")

# =========================
# 3. 定义 State
# =========================
class State(TypedDict):
    messages: Annotated[list, add_messages]
    name:str
    birthday:str

graph_builder = StateGraph(State)

# =========================
# 4. 定义人工协助工具
# =========================
@tool
def human_assistance(
    name:str,
    birthday:str,
    tool_call_id:Annotated[str,InjectedToolCallId]
)->str:
    """请求人类协助"""
    human_response=interrupt({
        "question":"是否正确？",
        "name": name,
        "birthday": birthday,
    })
    if human_response.get("correct","").lower().startswith("y"):
        verified_name=name
        verified_birthday=birthday
        response="正确，无需修改"
    else:
        verified_name=human_response.get("name",name)
        verified_birthday=human_response.get("birthday",birthday)
        response=f"修正:{human_response}"
    
    state_update={
        name:verified_name,
        birthday:verified_birthday,
        "messages":[ToolMessage(response,tool_call_id=tool_call_id)]
    }
    return Command(update=state_update)

# =========================
# 5. 定义搜索工具
# =========================
tool = TavilySearch(max_results=3)
tools = [tool, human_assistance]

# =========================
# 6. 绑定工具给 LLM
# =========================
llm_with_tools=llm.bind_tools(tools)

human_response=input("请输入需要人类协助的问题：")
human_command=Command(resume={"data": human_response})

# =========================
# 7. 定义 chatbot 节点
# =========================
def chatbot(state: State):
    response = llm_with_tools.invoke(state["messages"])
    return {"messages": [response]}

graph_builder.add_node("chatbot", chatbot)

# =========================
# 8. 定义 tools 节点
# =========================
tool_node=ToolNode(tools=tools)

graph_builder.add_node("tools", tool_node)

# def route_tools(state: State) :
#     if isinstance(state,list):cd
#         ai_messages=state[-1]
#     elif messages:=state.get("messages",[]):
#         ai_messages=messages[-1]
#     else:
#         raise ValueError("messages is empty in input state:{state}")
    
#     if hasattr(ai_messages,"tool_calls") and len(ai_messages.tool_calls) > 0:
#         return "tool_node"
#     return END

# graph_builder.add_conditional_edges("chatbot", route_tools,{"tool_node": "tool_node", END: END})

# =========================
# 9. 定义边
# chatbot -> 条件路由 -> tools 或 END
# tools -> chatbot
# START -> chatbot
# =========================
graph_builder.add_conditional_edges(
    "chatbot",
    tools_condition,
)
graph_builder.add_edge("tools", "chatbot")
graph_builder.add_edge(START, "chatbot")

# =========================
# 10. checkpoint / config / compile
# =========================
memory=MemorySaver()    #可改成PostgresSaver
config={"configurable":{"thread_id":"1"}}

graph = graph_builder.compile(checkpointer=memory)



# def debug_run(user_input: str):
#     for step in graph.stream(
#         {"messages": [{"role": "user", "content": user_input}]},
#         stream_mode="updates"
#         ,config=config
#     ):
#         for node_name, value in step.items():
#             print(f"\n>>> 节点: {node_name}")

#             if "messages" in value:
#                 last = value["messages"][-1]

#                 if hasattr(last, "tool_calls") and last.tool_calls:
#                     print("⚠️  模型触发 tool_calls:", last.tool_calls)
#                 else:
#                     print("💬 输出:", last.content)
    
#     # snapshot = graph.get_state(config)
#     # snapshot
#     # print("快照:", snapshot)


def debug_run(user_input: str):
    for step in graph.stream(
        {"messages": [{"role": "user", "content": user_input}]},
        stream_mode="updates",
        config=config
    ):
        for node_name, value in step.items():

            if "messages" not in value:
                continue

            last = value["messages"][-1]

            # Thought + Act
            if hasattr(last, "tool_calls") and last.tool_calls:
                tool_call = last.tool_calls[0]
                print("\n🧠 Thought: 我需要调用工具来获取信息")
                print(f"🔧 Act: {tool_call['name']}({tool_call['args']})")

            # OBS
            elif node_name == "tools":
                try:
                    data = json.loads(last.content)

                    if "results" in data and len(data["results"]) > 0:
                        top_result = data["results"][0]["content"]
                        print(f"👀 Obs: {top_result[:1024]}...")  # 截断展示
                    else:
                        print("👀 Obs: 无有效结果")

                except:
                    print("👀 Obs:", last.content[:1024])

            # Final_answer
            else:
                print(f"✅ Final Answer: {last.content}")

while True:
    try:
        user_input = input("User: ")
        if user_input.lower() in ["exit", "quit", "q"]:
            print("Goodbye!")
            break
        debug_run(user_input)
    except Exception as e:
        print("报错了：", repr(e))
        break