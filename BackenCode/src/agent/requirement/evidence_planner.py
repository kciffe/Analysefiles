import json
from langchain_core.messages import HumanMessage, SystemMessage

from .llm import get_llm_without_tools
from .prompt import _GENERATE_EVIDENCE_PROMPT
from ...workflow.requirement import ParseWorkFlowState


def _parse_plan_array(text: str) -> list[dict]:
    text = (text or "").strip()
    if not text:
        return []

    try:
        data = json.loads(text)
        return data if isinstance(data, list) else []
    except Exception:
        pass

    l = text.find("[")
    r = text.rfind("]")
    if l != -1 and r != -1 and r > l:
        try:
            data = json.loads(text[l : r + 1])
            return data if isinstance(data, list) else []
        except Exception:
            return []

    return []


def generate_evidence_agent(parse_workflow_state: ParseWorkFlowState) -> ParseWorkFlowState:
    print("\n⚠️ 进入 : generate_evidence_agent")

    llm = get_llm_without_tools()
    prompt = _GENERATE_EVIDENCE_PROMPT.format(
        requirement=parse_workflow_state["requirement"],
        candidate_documents=json.dumps(parse_workflow_state.get("candidate_documents", []), ensure_ascii=False),
    )

    result = llm.invoke(
        [
            SystemMessage(content="你必须只输出 JSON 数组，不要输出任何解释。"),
            HumanMessage(content=prompt),
        ]
    )

    content = result.content if isinstance(result.content, str) else str(result.content)
    plans = _parse_plan_array(content)

    print(f"➕ 生成的检索计划数量：{len(plans)}")
    for plan in plans:
        print(f"➕➕  - {plan}")
    parse_workflow_state["retrieval_plan"] = plans
    return parse_workflow_state
