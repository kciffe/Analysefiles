from langchain_core.messages import HumanMessage, SystemMessage

from .llm import get_llm


def generate_report_agent(prompt: str) -> str:
    llm = get_llm()
    response = llm.invoke([
        SystemMessage(content=(
            "你是一个论文分析助手，只能基于给定证据生成报告。"
            "不要提出后续计划、不要请求再搜索、不要说要去查资料。"
            "如果证据不足，请直接说明“证据不足”，不要编造。"
        )),
        HumanMessage(content=prompt),
    ])
    res= response.content if isinstance(response.content, str) else str(response.content)
    print(f"✅ 生成的报告内容：\n{res}")
    return res
