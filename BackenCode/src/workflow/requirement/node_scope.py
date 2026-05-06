from datetime import datetime

from typing_extensions import Literal
from langgraph.types import Command
from langgraph.graph import StateGraph,END,START
from langchain_core.messages import SystemMessage,HumanMessage,AIMessage,get_buffer_string
from src.workflow.requirement.state_scope import AgentState,ClarifyWithUser,ResearchQuestion
from src.workflow.requirement.agent.prompt import CLARIFY_WITH_USER_INSTRUCTIONS,GENERATE_RESEARCH_BRIEF
from src.agent.requirement.llm import get_llm,get_llm_without_tools
def get_today_str() -> str:
    """获得当前人类可读的日期字符串"""
    return datetime.now().strftime("%a %b %d, %Y").replace(" 0", " ")


def render_prompt(template: str, *, messages: str, date: str) -> str:
    return template.replace("{messages}", messages).replace("{date}", date)

# LLM
model = get_llm_without_tools()

# Nodes
def clarify_with_user(state:AgentState)->Command[Literal["write_research_brief","__end__"]]:
    """
    判断用户当前需求是否具备足够信息以进入生成结构化任务描述节点。

    通过结构化输出方式进行确定性判断，
    减少模型幻觉与需求理解偏差。

    根据判断结果：
    - 若信息充分，则进入生成结构化任务描述节点；
    - 若信息不足，则向用户发起需求澄清问题。
    """
    
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

    if response.need_clarification:
        return Command(
            goto=END, 
            update={"messages": [AIMessage(content=response.question)]}
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

