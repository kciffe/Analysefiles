from datetime import date
from typing import List, Literal

from pydantic import BaseModel

RequirementStatus = Literal["已发布", "运行中", "已完成", "已失败"]


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


class RequirementParseResponse(BaseModel):
    success: bool
    reportMarkdown: str | None = None


class RequirementParseResultQueryResponse(BaseModel):
    waiting: bool
    id: str
    name: str
    status: RequirementStatus
    createdAt: str
    result: RequirementParseResponse | None = None
    error: str | None = None
