# 真正创建 LangGraph 工作流。
from .state import ParseWorkFlowState
from .nodes import *
from langgraph.graph import StateGraph,END
def build_requirement_graph():
    
    builder=StateGraph(ParseWorkFlowState)

    # 注册节点
    builder.add_node("prepare_query",prepare_query_node)
    builder.add_node("retrieval_documents",retrieval_documents_node)
    builder.add_node("generate_plans",generate_plans_node)
    builder.add_node("read_sections",read_sections_node)
    builder.add_node("judge_evidence",judge_evidence_node)
    # builder.add_node("refine_keywords",refine_keywords_node)
    builder.add_node("generate_report",generate_report_node)

    # 设置入口
    builder.set_entry_point("prepare_query")

    builder.add_edge("prepare_query","retrieval_documents")
    builder.add_edge("retrieval_documents","generate_plans")
    builder.add_edge("generate_plans","read_sections")
    builder.add_edge("read_sections","judge_evidence")

    # 判断是否满足需求分析
    builder.add_conditional_edges("judge_evidence",{
        ParseWorkFlowState.evidence_sufficient: "generate_report",
        not ParseWorkFlowState.evidence_sufficient: "read_sections",
        }
    )

    #结束节点
    builder.add_edge("generate_report",END)

    return builder.compile()

# 导出graph
requirement_graph=build_requirement_graph()