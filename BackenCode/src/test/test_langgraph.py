from dotenv import load_dotenv
from ..worker import run_requirement_job
from ..schemas.requirement_type import RequirementParseRequest
from ..service import create_requirement_job

load_dotenv()  # 加载 .env 文件中的环境变量

req=RequirementParseRequest(
    name="测试需求解析",    
    detail="分析近期的NLP领域的deepresearch技术变化",
    startDate="2020-01-01",
    endDate="2026-12-31",
    docTypes=["ACL", "arxiv"],
    keywords=["NLP"],
)   


create_requirement_job(
    item_id="test",
    name=req.name,
    created_at="2023-01-01T00:00:00Z",
    requirement_data=req
)
print("开始执行任务")
run_requirement_job("test", req)

