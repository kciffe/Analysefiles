import sys
from pathlib import Path

#测试日志库输入
try:
    from ..db import get_session
    from .documents import store_agent_logs
except ImportError:  # direct script execution fallback
    project_root = Path(__file__).resolve().parents[2]
    if str(project_root) not in sys.path:
        sys.path.insert(0, str(project_root))
    from src.db import get_session
    from src.repositories.documents import store_agent_logs

with get_session() as session:
    store_agent_logs(session, task_name="test", status="success", message="test")
