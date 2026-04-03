import json
from langchain_core.messages import AIMessage,ToolMessage

from .state import ParseWorkFlowState
from ...mcp.tool_registry import TOOL_REGISTRY
from ...agent.report_generator import generate_report_agent
from ...agent import generate_report_plans_agent
from .prompt import _GENERATE_REPORT_PROMPT, _GENERATE_PLANS_PROMPT
from ...schemas.requirement_type import SearchDocumentsRequest

# 实现每一个 graph node 的具体逻辑。

def prepare_query_node(workflow_state:ParseWorkFlowState)->ParseWorkFlowState:
    # 准备 query node 的输入，主要是根据当前状态生成检索关键词。
    # 这里可以调用一些工具函数来生成关键词，比如基于当前需求和已选文档的关键词提取。
    # 生成的关键词存储在 workflow_state.current_keywords 中。
    #TODO:调用工具生成所需关键词
    print("\n✅ 进入 : prepare_query_node")
    workflow_state["current_step"] = "prepare_query_node"
    return workflow_state

def retrieval_documents_node(workflow_state:ParseWorkFlowState)->ParseWorkFlowState:
    # 根据 workflow_state.current_keywords 进行文献检索，得到候选文档列表。
    # 检索结果存储在 workflow_state.candidate_documents 中。
    print("\n✅ 进入 : retrieval_documents_node")
    return {
        "messages": [
            AIMessage(
                content=f"执行检索相关文档节点，当前关键词：{workflow_state['search_document_request'].keywords}",
                tool_calls=[
                    {
                        "name":"search_documents",
                        "args":{
                            "keywords":workflow_state["search_document_request"].keywords,
                            "doc_types":workflow_state["search_document_request"].doc_types,
                            "start_date":workflow_state["search_document_request"].start_date,
                            "end_date":workflow_state["search_document_request"].end_date,
                            "limit":workflow_state["search_document_request"].limit
                        }
                    }
                ]
            )
        ]
    }
    # workflow_state["candidate_documents"] = TOOL_REGISTRY["search_documents"](
    #     keywords=workflow_state["search_document_request"].keywords,
    # )
    # workflow_state["current_step"] = "retrieval_documents_node"
    # return workflow_state
def collect_retrieval_results_node(workflow_state:ParseWorkFlowState)->ParseWorkFlowState:
    # 收集检索工具的调用结果，更新 workflow_state.candidate_documents。
    print("\n✅ 进入 : collect_retrieval_results_node")
    message=workflow_state.get("messages",[])
    doc=[]

    #倒序找最后一个search_documents工具调用的结果
    for msg in reversed(message):
        if not isinstance(msg, ToolMessage):
            continue
        if getattr(msg,"name",None) == "search_documents":
            continue
       
        content=msg.content

        if isinstance(content,str):
           parsed=json.loads(content)
        else:
            parsed=content
        
        if isinstance(parsed,list):
            doc=parsed
        elif isinstance(parsed, dict) and "data" in parsed and isinstance(parsed["data"], list):
            docs = parsed["data"]
        
        break
    
    workflow_state["candidate_documents"] = doc
    workflow_state["current_step"] = "collect_retrieval_results_node"
    return workflow_state

def generate_plans_node(workflow_state:ParseWorkFlowState)->ParseWorkFlowState:
    # 根据 workflow_state.candidate_documents，生成需求分析的规划，存储在 workflow_state.plans 中。
    print("\n✅ 进入 : generate_plans_node")
    #TODO:计划生成规划
    workflow_state["plans"] = generate_report_plans_agent(
        prompt=_GENERATE_PLANS_PROMPT.format(requirement=workflow_state["requirement"],)
    )
    workflow_state["current_step"] = "generate_plans_node"
    return workflow_state

def read_sections_node(workflow_state:ParseWorkFlowState)->ParseWorkFlowState:
    # 根据 workflow_state.selected_documents，读取其中的相关章节内容，存储在 workflow_state.already_read_sections 中。
    print("\n✅ 进入 : read_sections_node")
    return AIMessage(
        content=f"执行阅读文档相关章节节点，当前选中文档：{workflow_state['selected_documents']}，当前计划：{workflow_state['plans']}",
        tool_calls=[
            {
                "name":"search_paragraph",
                "args":{
                    
                }
            }
        ]
    )
    # already_read_sections = [] 
    # while(len(workflow_state["plans"]) > 0):     
    #     plan = workflow_state["plans"].pop(0)
    # workflow_state["already_read_sections"] = already_read_sections
    # workflow_state["current_step"] = "read_sections_node"
    # return workflow_state


def judge_evidence_node(workflow_state:ParseWorkFlowState)->ParseWorkFlowState:
    # 判断 workflow_state.already_read_sections 中的内容是否满足需求分析的证据要求。
    # 如果plans为空，则所有需求完成，进行下一阶段
    print("\n✅ 进入 : judge_evidence_node")
    if(len(workflow_state["plans"]) > 0):
        workflow_state["evidence_sufficient"] = False
    else:
        workflow_state["evidence_sufficient"] = True

    workflow_state["current_step"] = "judge_evidence"
    return workflow_state

def refine_keywords_node(workflow_state:ParseWorkFlowState)->ParseWorkFlowState:
    # 根据 workflow_state.plans，生成新的检索关键词，更新 workflow_state.current_keywords。
    print("\n✅ 进入 : refine_keywords_node")
    current_keywords = [] #TODO:调用工具根据 plan 生成新的检索关键词
    workflow_state["current_keywords"] = current_keywords
    workflow_state["current_step"] = "refine_keywords_node"
    return workflow_state

def generate_report_node(workflow_state:ParseWorkFlowState)->ParseWorkFlowState:
    # 根据 workflow_state.already_read_sections 中的内容，生成最终的分析报告，存储在 workflow_state.report_markdown 中。
    print("\n✅ 进入 : generate_report_node")
    prompt=_GENERATE_REPORT_PROMPT.format(
        requirement = workflow_state["requirement"],
        already_read_sections = workflow_state["already_read_sections"]
    )
    # 调 LLM，总结生成报告
    report_markdown = generate_report_agent(
        prompt=prompt,
    )

    workflow_state["report_markdown"] = report_markdown
    return workflow_state
