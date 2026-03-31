import json
from langchain_core.messages import HumanMessage,SystemMessage
from .llm import get_llm
def generate_report_plans_agent(prompt:str) -> str:
    llm = get_llm()
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