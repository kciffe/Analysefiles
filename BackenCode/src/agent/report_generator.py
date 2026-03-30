import os
from openai import  OpenAI
from langchain_core.messages import HumanMessage,SystemMessage

API_KEY =os.getenv("DEEPSEEK_API_KEY")
llm = OpenAI(
    model = "deepseek-chat",
    base_url="https://api.deepseek.com",
    api_key=API_KEY
)
def generate_report_agent(prompt:str) -> str:
    response = llm.invoke(
        SystemMessage(content="你是一个论文分析助手，你需要根据用户输入的需求以及相关文档内容，返回一篇需求分析报告，并给出参考文献。"),
        HumanMessage(content=prompt))
    
    return response.content

