from datetime import datetime

from typing_extensions import Literal
from langgraph.types import Command,interrupt
from langgraph.graph import StateGraph,END,START
from langchain_core.messages import SystemMessage,HumanMessage,AIMessage,get_buffer_string
from src.workflow.requirement.state_scope import AgentState,ClarifyWithUser,ResearchQuestion
from src.workflow.requirement.agent.prompt import CLARIFY_WITH_USER_INSTRUCTIONS,GENERATE_RESEARCH_BRIEF
from src.agent.requirement.llm import get_llm,get_llm_without_tools
from src.utils import log_success, log_warning

def get_today_str() -> str:
    """获得当前人类可读的日期字符串"""
    return datetime.now().strftime("%a %b %d, %Y").replace(" 0", " ")


def render_prompt(template: str, *, messages: str, date: str) -> str:
    return template.replace("{messages}", messages).replace("{date}", date)


def has_user_clarification_reply(state: AgentState) -> bool:
    messages = state.get("messages", [])
    return any(isinstance(message, AIMessage) for message in messages) and sum(
        1 for message in messages if isinstance(message, HumanMessage)
    ) >= 2


def fallback_clarification_question() -> str:
    return (
        "我可以开始做这个研究，不过想先确认两个点，避免报告方向跑偏：\n\n"
        "1. 你更希望报告侧重技术路线梳理，还是代表方法/模型对比？\n"
        "2. 输出上你希望偏综述报告，还是偏可落地的技术选型建议？\n\n"
        "如果没有特别偏好，也可以回复“按常规综述报告来”，我会按默认方向继续。"
    )

# LLM
model = get_llm_without_tools()

# Nodes
def clarify_with_user(state:AgentState)->Command[Literal["write_research_brief","clarify_with_user"]]:
    """
    判断用户当前需求是否具备足够信息以进入生成结构化任务描述节点。

    通过结构化输出方式进行确定性判断，
    减少模型幻觉与需求理解偏差。

    根据判断结果：
    - 若信息充分，则进入生成结构化任务描述节点；
    - 若信息不足，则向用户发起需求澄清问题。
    """
    log_success("进入 : clarify_with_user")

    structured_output_model=model.with_structured_output(ClarifyWithUser)

    # get_buffer_string用于将langchain的格式化消息列表转化为string
    response=structured_output_model.invoke([
        HumanMessage(
            content=render_prompt(
                CLARIFY_WITH_USER_INSTRUCTIONS,
                messages=get_buffer_string(messages=state["messages"]),
                date=get_today_str()
            )
        )
    ])

    should_clarify = response.need_clarification or not has_user_clarification_reply(state)

    if should_clarify:
        question = response.question or fallback_clarification_question()
        log_warning("需求需要用户澄清")
        user_answer=interrupt({
            "question":question,
            "type": "requirement_clarification"
        })
        return Command(
            goto="clarify_with_user", 
            update={"messages": [
                AIMessage(content=question),
                HumanMessage(content=user_answer),
            ]}
        )
    else:
        return Command(
            goto="write_research_brief",
            update={"messages":[AIMessage(content=response.verification)]}
        )

def write_research_brief(state: AgentState) :
    """
    将用户历史对话内容整理并转换为结构化的研究任务描述（Research Brief）。

    通过结构化输出方式，
    确保生成的研究任务具备完整、规范的格式，
    并包含后续技术分析、文档检索与报告生成所需的关键信息。
    """

    struct_output_model=model.with_structured_output(ResearchQuestion)

    response=struct_output_model.invoke([
        HumanMessage(
            content=render_prompt(
                GENERATE_RESEARCH_BRIEF,
                messages=get_buffer_string(messages=state["messages"]),
                date=get_today_str()
            )
        )
    ])

    return {
        "research_brief":response.research_brief,
        "supervisor_messages":[HumanMessage(content=f"{response.research_brief}")]
    }

