from typing import List

from pydantic import BaseModel

class LabelSchema(BaseModel):
    label_name: str
    sub_labels: List[str]

class QueryLabelsResponse(BaseModel):
    schemas: List[LabelSchema]