from src.service.requirement_jobs import (
    get_requirement_job,
    set_requirement_job_processing,
    set_requirement_job_success,
    set_requirement_job_failed,
)

from src.agent.requirement_agent import run_requirement_agent

def run_requirement_job(item_id: str):

    job = get_requirement_job(item_id)
    if job is None:
        return

    set_requirement_job_processing(item_id)

    try:
        result = run_requirement_agent(job["requirementData"])

        set_requirement_job_success(
            item_id,
            result=result,
        )

    except Exception as e:
        set_requirement_job_failed(
            item_id,
            error=str(e),
        )