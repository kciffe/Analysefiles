from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage,SystemMessage
from .llm import get_llm
def generate_report_agent(prompt:str) -> str:
    llm = get_llm()
    response = llm.invoke(
        SystemMessage(content="你是一个论文分析助手，你需要根据用户输入的需求以及相关文档内容，返回一篇需求分析报告，并给出参考文献。"),
        HumanMessage(content=prompt))
    
    return response.content

