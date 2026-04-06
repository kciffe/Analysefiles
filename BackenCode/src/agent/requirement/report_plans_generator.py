import json
from langchain_core.messages import HumanMessage, SystemMessage

from .llm import get_llm


def generate_report_plans_agent(prompt: str):
    llm = get_llm()
    response = llm.invoke([
        SystemMessage(content="你是一个技术分析规划助手，负责根据用户需求生成检索证据的具体计划。输出请严格使用 JSON。"),
        HumanMessage(content=prompt),
    ])

    content = response.content if isinstance(response.content, str) else str(response.content)
    try:
        data = json.loads(content)
    except json.JSONDecodeError:
        cleaned = content.replace("```json", "").replace("```", "").strip()
        data = json.loads(cleaned)

    plans = data.get("plans", [])
    if not isinstance(plans, list):
        raise ValueError("plans 应该是一个列表")
    if not all(isinstance(plan, str) for plan in plans):
        raise ValueError("plans 列表中的每一项应该是字符串")


    return plans
   