from datetime import date
from typing import List, Literal

from pydantic import BaseModel

RequirementStatus = Literal["已完成", "已发布", "运行中"]


class RequirementParseRequest(BaseModel):
    name: str
    startDate: date
    endDate: date
    docTypes: List[str]
    keywords: List[str]
    detail: str


class ReportBlockText(BaseModel):
    id: str
    type: Literal["text"]
    title: str
    content: str


class ReportBlockTable(BaseModel):
    id: str
    type: Literal["table"]
    title: str
    columns: List[str]
    rows: List[List[str]]


class RequirementParseRecived(BaseModel):
    id: str
    name: str
    status: RequirementStatus
    createdAt: str


class ReportSchema(BaseModel):
    title: str
    summary: str
    blocks: List[ReportBlockText | ReportBlockTable]


class RequirementParseResponse(BaseModel):
    success: bool
    report: ReportSchema


class RequirementParseResultQueryResponse(BaseModel):
    id: str
    name: str
    status: RequirementStatus
    createdAt: str
    result: RequirementParseResponse | None = None
    error: str | None = None
