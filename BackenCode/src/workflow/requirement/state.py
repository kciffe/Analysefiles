#定义 LangGraph 的共享状态
from typing import TypedDict,Annotated
from langgraph.graph.message import add_messages
from ...repositories.documents import RetrievedDocument
from ...schemas.requirement_type import EvidenceSectionPair,SearchDocumentsRequest,ReTrievalPlan
#------------
# PARSE
#------------
class ParseWorkFlowState(TypedDict):
    """LangGraph 工作流的共享状态结构定义"""



    messages:Annotated[list, add_messages]
    tool_traces: list[dict]                     # 每轮工具调用摘要

    #===============
    # 澄清步骤
    #===============
    # research_brief: str | None
    # need_clarification: bool
    # clarification_question: str | None
    # scope_messages: Annotated[list, add_messages] #用户澄清对话历史，这里暂不考虑保存

    #===============
    # 检索步骤
    #===============
    requirement: str                     # 用户需求
    task_name: str                       # 任务名/日志任务标识
    search_document_request: SearchDocumentsRequest | None # 检索工具的输入参数

    candidate_documents: list[RetrievedDocument]        # 本轮检索得到的候选文档
    retrieval_plan: list[ReTrievalPlan] | None          # 检索计划
    pending_read_map: dict[str, dict]                   # 用于查询检索工具id以得到后续检索出的对应的段落信息

    plans: list[str] | None              # 论文段落需求（证据）缺口描述
    already_read_sections: list[EvidenceSectionPair]    # 已读取出的论文段落信息（证据）
    evidence_sufficient: bool    # 证据是否充分的判断结果

    report_markdown: str | None          # 最终报告
    current_step: str                    # 当前节点名/步骤名
    status: str                          # processing / success / failed/pending
    error_message: str | None            # 异常信息

