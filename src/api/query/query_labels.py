from fastapi import APIRouter
from ...repositories.labels import Labels, select_labels
from .schemas import LabelSchema, QueryLabelsResponse
from ..schemas import ResponseModel

router = APIRouter()


# TODO: Add more validation in the future
@router.get("/labels", response_model=ResponseModel[QueryLabelsResponse])
async def get_labels():

    available_labels = []
    repo_labels = select_labels()
    for label in repo_labels:
        available_labels.append(
            LabelSchema(
                label_name=label.top_label, 
                sub_labels=label.sub_label
            )
        )
    return ResponseModel(
        code=200,
        data=QueryLabelsResponse(schemas=available_labels)
    )