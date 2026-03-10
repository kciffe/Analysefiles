from __future__ import annotations

from copy import deepcopy
from threading import Lock
from typing import Any

_jobs: dict[str, dict[str, Any]] = {}
_jobs_lock = Lock()


def create_requirement_job(
    *,
    item_id: str,
    name: str,
    created_at: str,
    requirement_data: dict[str, Any],
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


def set_requirement_job_success(item_id: str, *, result: dict[str, Any]) -> None:
    with _jobs_lock:
        job = _jobs.get(item_id)
        if job is not None:
            job["status"] = "success"
            job["result"] = deepcopy(result)
            job["error"] = None


def set_requirement_job_failed(item_id: str, *, error: str) -> None:
    with _jobs_lock:
        job = _jobs.get(item_id)
        if job is not None:
            job["status"] = "failed"
            job["error"] = error
