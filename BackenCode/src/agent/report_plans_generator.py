import os
import json
from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage,SystemMessage
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")

llm= ChatOpenAI(
    model = "deepseek-chat",
    base_url="https://api.deepseek.com",
    api_key=DEEPSEEK_API_KEY
)   

def generate_report_agent(prompt:str) -> str:
    response=llm.invoke(
        SystemMessage(content="你是一个技术分析规划助手，负责根据用户需求生成检索证据的具体计划。输出严格按照json格式"),
        HumanMessage(content=prompt)
    )
    try:
        data=json.loads(response.content)["plans"]
    except json.JSONDecodeError:
        cleaned=response.content.replace("```json","").replace("```","").strip()
        data=json.loads(cleaned)

    plans=data.get("plans",[])
    if not isinstance(plans,list):
        raise ValueError("生成的计划格式不正确，plans应该是一个列表")
    if not all(isinstance(plan, dict) for plan in plans):
        raise ValueError("生成的计划格式不正确，plans列表中的每一项应该是一个字典")
    
    return plans