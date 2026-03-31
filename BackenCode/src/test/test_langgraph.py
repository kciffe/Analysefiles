from ..worker import run_requirement_job
from ..schemas.requirement_type import RequirementParseRequest

req=RequirementParseRequest(
    name="测试需求解析",    
    detail="分析近期的NLP领域的deepresearch技术变化",
    startDate="2020-01-01",
    endDate="2026-12-31",
    docTypes=["ACL", "arxiv"],
    keywords=["NLP"],
)   


run_requirement_job("test", req)

