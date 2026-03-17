from typing import Any

from pydantic import BaseModel


class ParseResponse(BaseModel):
    md: str
    # label_1 - label_2 - label_3
    labels: str
