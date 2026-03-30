# parse模块下的类型定义文件
from datetime import date
from typing import List
from pydantic import BaseModel,Field

class EvidenceSectionPair(BaseModel):
    """证据-文档对"""
    evidence:str = Field(None, description="需求分析相关的证据内容")
    section:str = Field(None, description="相关的文档片段")

class SearchDocumentsRequest(BaseModel):
    """搜索文档请求参数"""
    keywords: list[str] | None = Field(None, description="搜索的关键词")
    doc_types: list[str] | None = Field(None, description="文档类型,如ACL、arxiv等")
    start_date: str | None = Field(None, description="文档发布的最早时间")
    end_date: str | None = Field(None, description="文档发布的最晚时间")
    limit: int = Field(128, description="返回的文档数量上限")   

class RequirementParseRequest(BaseModel):
    name: str
    startDate: date
    endDate: date
    docTypes: List[str]
    keywords: List[str]
    detail: str