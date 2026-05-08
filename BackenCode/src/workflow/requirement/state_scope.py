
from typing_extensions import Optional,Annotated,Sequence
from langgraph.graph import MessagesState
from langgraph.graph.message import add_messages
from langchain_core.messages import BaseMessage
from pydantic import BaseModel,Field

class AgentInputState(MessagesState):
    """输入状态用于多Agent - 只包含用户输入的信息"""
    pass

class AgentState(MessagesState):
    """
    多 Agent 技术分析系统的核心状态定义。

    在 MessagesState 基础上扩展，用于在整个工作流中共享和传递关键信息，
    包括需求解析、文档检索、证据收集以及报告生成等阶段的数据。

    说明：
    - 该 State 在 LangGraph 主工作流中作为共享内存，被各节点逐步更新。
    - 为兼容子图（subgraph）执行及状态合并机制，部分字段在不同 State 中重复定义，
    属于设计上的冗余，用于保证跨子流程的数据一致性与可追踪性。
    """
    # 需求概述
    research_brief:Optional[str]
    # 多 agent 之间的调度通信记录 暂时不需要
    # supervisor_messages:Annotated[Sequence[BaseMessage],add_messages]

    # ....

class ClarifyWithUser(BaseModel):
    """用于判断是否需要向用户发起轻量需求澄清，并生成对应问题与确认信息的结构化输出。"""
    need_clarification:bool =Field(
        description="是否需要用户继续澄清需求内容。默认最多追问一次；用户已有主题和大致目标时通常为 false。"
    )
    question:str=Field(
        description="用于询问需要用户澄清的具体内容。问题应简短自然，最多 2-3 个问题，并提供默认继续方案。"
    )
    verification:str=Field(
        description="用于返回给用户当前需求信息已经足以支撑开启后续研究的确认信息。"
    )

class ResearchQuestion(BaseModel):
    """
    研究问题生成阶段的结构化输出 Schema。

    用于将用户原始需求转化为标准化研究任务（Research Brief），
    作为后续检索与分析流程的输入。
    """

    research_brief: str = Field(
        description="标准化后的技术分析任务描述，用于指导后续文档检索、证据收集与报告生成。"
    )
