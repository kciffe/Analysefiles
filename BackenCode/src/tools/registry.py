from .search_paragraph import search_paragraph
from .search_documents import search_documents

#给模型看的
TOOLS=[
    search_paragraph,
    search_documents
]

TOOL_FUNCTIONS={
    "search_paragraph":search_paragraph,
    "search_documents":search_documents
}