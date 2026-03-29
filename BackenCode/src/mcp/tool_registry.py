from ..tools.search_documents import search_documents
from ..tools.search_paragraph import search_paragraph

TOOL_REGISTRY = {
    "search_documents": search_documents,
    "search_paragraph": search_paragraph,
}