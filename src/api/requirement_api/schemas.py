from datetime import date, datetime
from typing import List

from pydantic import BaseModel


class RequirementParseRequest(BaseModel):
    name: str
    startDate: date
    endDate: date
    docTypes: List[str]
    keywords: List[str]
    detail: str


class RequirementSubmitResponse(BaseModel):
    id: str
    name: str
    status: str
    createdAt: datetime
