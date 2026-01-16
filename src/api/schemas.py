from typing import Generic, TypeVar
from pydantic import BaseModel

T = TypeVar("_T")

class ResponseModel(Generic[T], BaseModel):
    code: int
    msg: str | None
    data: T