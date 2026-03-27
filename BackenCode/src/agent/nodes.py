from .state import WorkFlowState
from ..tools.search_documents import search_documents
# 实现每一个 graph node 的具体逻辑。

def prepare_query_node(workflow_state:WorkFlowState)->WorkFlowState:
    # 准备 query node 的输入，主要是根据当前状态生成检索关键词。
    # 这里可以调用一些工具函数来生成关键词，比如基于当前需求和已选文档的关键词提取。
    # 生成的关键词存储在 workflow_state.current_keywords 中。
    current_keywords = workflow_state.current_keywords #TODO:调用工具生成所需关键词
    workflow_state.current_keywords = current_keywords
    return workflow_state

def retrieval_documents_node(workflow_state:WorkFlowState)->WorkFlowState:
    # 根据 workflow_state.current_keywords 进行文献检索，得到候选文档列表。
    # 检索结果存储在 workflow_state.candidate_documents 中。
    candidate_documents = search_documents()
    workflow_state.candidate_documents = candidate_documents
    return workflow_state

def rank_documents_node(workflow_state:WorkFlowState)->WorkFlowState:
    # 对 workflow_state.candidate_documents 进行相关性排序，选出高相关的文档存储在 workflow_state.selected_documents 中。
    selected_documents = workflow_state.candidate_documents #TODO:调用工具进行文档排序和筛选
    workflow_state.selected_documents = selected_documents
    return workflow_state

def read_sections_node(workflow_state:WorkFlowState)->WorkFlowState:
    # 根据 workflow_state.selected_documents，读取其中的相关章节内容，存储在 workflow_state.already_read_sections 中。
    already_read_sections = [] #TODO:调用工具读取文档章节内容
    workflow_state.already_read_sections = already_read_sections
    return workflow_state


def judge_evidence_node(workflow_state:WorkFlowState)->WorkFlowState:
    # 判断 workflow_state.already_read_sections 中的内容是否满足需求分析的证据要求。
    # 如果满足，更新 workflow_state.plan 为 None；如果不满足，生成新的 plan 存储在 workflow_state.plan 中。
    plan = None #TODO:调用工具判断证据是否满足需求，并生成新的 plan
    workflow_state.plan = plan
    return workflow_state

def refine_keywords_node(workflow_state:WorkFlowState)->WorkFlowState:
    # 根据 workflow_state.plan，生成新的检索关键词，更新 workflow_state.current_keywords。
    current_keywords = [] #TODO:调用工具根据 plan 生成新的检索关键词
    workflow_state.current_keywords = current_keywords
    return workflow_state

def generate_report_node(workflow_state:WorkFlowState)->WorkFlowState:
    # 根据 workflow_state.already_read_sections 中的内容，生成最终的分析报告，存储在 workflow_state.report_markdown 中。
    report_markdown = "" #TODO:调用工具根据已读取的章节内容生成分析报告
    workflow_state.report_markdown = report_markdown
    return workflow_state

