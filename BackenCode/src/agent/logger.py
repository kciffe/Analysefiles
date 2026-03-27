from ..repositories.documents import store_agent_logs
from ..db import get_session
# 封装“写 agent 日志到数据库”的统一入口。

def log_agent_event(task_name:str,status:str,message:str)->None:
    """
    记录 agent 事件到数据库
    Args:
        task_name: 任务名/日志任务标识
        status: 事件状态，如 "processing", "success", "failed"
        message: 事件描述信息
    """
    with get_session() as session:
        store_agent_logs(session, task_name=task_name,status=status,message=message)
def log_node_start(task_name:str,node_name:str,message:str)->None:
    log_agent_event(task_name,"processing",f"节点: {node_name} - 开始执行 - {message}")

def log_node_end(task_name:str,node_name:str,message:str)->None:
    log_agent_event(task_name,"success",f"节点: {node_name} - 执行成功 - {message}")

def log_node_error(task_name:str,node_name:str,error_message:str)->None:
    log_agent_event(task_name,"failed",f"节点: {node_name} - 执行失败 - {error_message}")

