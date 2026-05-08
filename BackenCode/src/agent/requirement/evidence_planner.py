import json
from langchain_core.messages import HumanMessage, SystemMessage

from .llm import get_llm_without_tools
from .prompt import _GENERATE_EVIDENCE_PROMPT
from ...workflow.requirement import ParseWorkFlowState
from ...schemas.requirement_type import ReTrievalPlan
from ...utils import log_info

def _parse_plan_array(text: str) -> list[ReTrievalPlan]:
    text = (text or "").strip()
    if not text:
        return []

    try:
        data = json.loads(text)

        return [ReTrievalPlan(**plan) for plan in data] if isinstance(data, list) else []
    except Exception:
        pass

    l = text.find("[")
    r = text.rfind("]")
    if l != -1 and r != -1 and r > l:
        try:
            data = json.loads(text[l : r + 1])
            return [ReTrievalPlan(**plan) for plan in data] if isinstance(data, list) else []
        except Exception:
            return []

    return []


def generate_evidence_agent(parse_workflow_state: ParseWorkFlowState) -> list[ReTrievalPlan]:
    llm = get_llm_without_tools()
    from .prompt import _EVALUATION_RUBRIC
    prompt = _GENERATE_EVIDENCE_PROMPT.format(
        evaluation_rubric=_EVALUATION_RUBRIC,
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

    log_info(f"生成的检索计划数量：{len(plans)}")
    
    return  plans
