from .search_paragraph import search_paragraph,search_paragraph_tool
from .search_documents import search_documents,search_documents_tool

#给模型看的
TOOLS=[
    search_paragraph_tool,
    search_documents_tool

]

TOOL_FUNCTIONS={
    "search_paragraph":search_paragraph,
    "search_documents":search_documents
}