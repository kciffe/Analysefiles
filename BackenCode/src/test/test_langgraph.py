from dotenv import load_dotenv

from ..schemas.requirement_type import RequirementParseRequest
from ..service import create_requirement_job
from ..utils import log_error, log_info, log_success
from ..worker import run_requirement_job

load_dotenv()

req = RequirementParseRequest(
    name="测试需求解析",
    detail="分析近期NLP领域的deepresearch技术变化",
    startDate="2020-01-01",
    endDate="2026-12-31",
    docTypes=["ACL", "arxiv"],
    keywords=["NLP"],
)

create_requirement_job(
    item_id="test",
    name=req.name,
    created_at="2023-01-01T00:00:00Z",
    requirement_data=req,
)
log_info("开始执行任务")
final_state = run_requirement_job("test", req)

if final_state is None:
    log_error("任务未找到")
else:
    log_success("任务完成")
    log_info(f"候选文档数: {len(final_state.get('candidate_documents') or [])}")
    log_info(f"工具追踪条数: {len(final_state.get('tool_traces') or [])}")
