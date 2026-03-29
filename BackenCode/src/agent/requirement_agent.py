from ..mcp.tool_registry import TOOL_REGISTRY


def run_requirement_agent(data: dict):

    # 模拟 agent 行为（后面换 LangGraph）
    
    # 示例：先调用检索工具
    tool = TOOL_REGISTRY["search_documents"]

    result = tool(
        keywords=data.get("keywords"),
        doc_types=data.get("docTypes"),
        start_date=data.get("startDate"),
        end_date=data.get("endDate"),
    )

    return {
        "step": "search_documents",
        "result": result,
    }