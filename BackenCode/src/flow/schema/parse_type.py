# parse模块下的类型定义文件

from pydantic import BaseModel

class EvidenceSectionPair(BaseModel):
    """证据-文档片段"""
    evidence:str = "",
    section:str = ""