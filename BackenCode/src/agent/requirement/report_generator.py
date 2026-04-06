from langchain_core.messages import HumanMessage, SystemMessage

from .llm import get_llm


def generate_report_agent(prompt: str) -> str:
    llm = get_llm()
    response = llm.invoke([
        SystemMessage(content="你是一个论文分析助手，需要根据用户需求和相关文档内容返回一篇需求分析报告，并给出参考文献。"),
        HumanMessage(content=prompt),
    ])
    return response.content if isinstance(response.content, str) else str(response.content)
