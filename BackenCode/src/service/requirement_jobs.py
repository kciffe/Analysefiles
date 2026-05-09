from __future__ import annotations
from typing import List
from copy import deepcopy
from threading import Lock
from typing import Any
from ..schemas import RequirementParseRequest

_jobs: dict[str, dict[str, Any]] = {}
_jobs_lock = Lock()


def create_requirement_job(
    *,
    item_id: str,
    name: str,
    created_at: str,
    requirement_data: RequirementParseRequest,
) -> None:
    with _jobs_lock:
        _jobs[item_id] = {
            "id": item_id,
            "name": name,
            "status": "received",
            "createdAt": created_at,
            "requirementData": deepcopy(requirement_data),
            "result": None,
            "error": None,
            "clarificationQuestion": None,
            "pendingClarificationAnswer": None,
            "messages": [],
        }


def get_requirement_job(item_id: str) -> dict[str, Any] | None:
    with _jobs_lock:
        job = _jobs.get(item_id)
        return deepcopy(job) if job is not None else None


def set_requirement_job_processing(item_id: str) -> None:
    with _jobs_lock:
        job = _jobs.get(item_id)
        if job is not None:
            job["status"] = "processing"
            job["clarificationQuestion"] = None


def set_requirement_job_success(item_id: str, *, result: dict[str, Any] | None = None) -> None:
    with _jobs_lock:
        job = _jobs.get(item_id)
        if job is not None:
            job["status"] = "success"
            job["error"] = None
            job["result"] = deepcopy(result)


def set_requirement_job_failed(item_id: str, *, error: str) -> None:
    with _jobs_lock:
        job = _jobs.get(item_id)
        if job is not None:
            job["status"] = "failed"
            job["error"] = error

# 设定状态clarifying
def set_requirement_job_clarifying(item_id:str,question:str)->None:
    with _jobs_lock:
        job=_jobs.get(item_id)
        if job is not None:
            job["status"]="clarifying"
            job["clarificationQuestion"]=question
            job["pendingClarificationAnswer"]=None
            job["error"]=None


def set_requirement_job_pending_answer(item_id: str, answer: str) -> None:
    with _jobs_lock:
        job = _jobs.get(item_id)
        if job is not None:
            job["status"] = "processing"
            job["clarificationQuestion"] = None
            job["pendingClarificationAnswer"] = answer
            job["error"] = None


def pop_requirement_job_pending_answer(item_id: str) -> str | None:
    with _jobs_lock:
        job = _jobs.get(item_id)
        if job is None:
            return None
        answer = job.get("pendingClarificationAnswer")
        job["pendingClarificationAnswer"] = None
        return answer

# 追加消息函数
def append_requirement_job_message(item_id: str, role: str, content: str) -> None:
    with _jobs_lock:
        job = _jobs.get(item_id)
        if job is not None:
            job.setdefault("messages", []).append({
                "role": role,
                "content": content,
            })
