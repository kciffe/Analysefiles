# DeepResearch

## QuickStart
- 项目用uv管理，先去装uv
```bash
uv venv -p 3.12
uv sync
```

## 启动
Server mode
```bash
uvicorn src.api.main:app --host 0.0.0.0 --port 8000
```
Development mode
```
uvicorn src.api.main:app --reload
ssh -N -L 18081:127.0.0.1:8081 -p 10611 root@10.0.6.135
uv run uvicorn src.api.main:app --reload --env-file .env

```

## 批量导入文档到三张表
启动参数第一个位置为输入目录路径：
```bash
uv run python -m src.scripts.batch_import_docs "D:\\8\\Desktop\\papers" --recursive
```

常用参数：
```bash
--extensions .pdf,.docx,.md
--source arxiv
--publish-venue "arXiv预印本"
--refresh-existing
--mineru-timeout 180
--mineru-retries 2
--retry-wait 2
# 默认不读取系统代理变量，避免 localhost 走 http_proxy 卡住
# 如确实需要代理再加：
--trust-env-proxy
```

默认已关闭 path 去重：同路径文件不会自动跳过。  
`--refresh-existing` 会按路径自动执行“先删后重建”，删除顺序为 `doc_parsed -> file_metadata -> file_resource`。  
`--overwrite` 目前仅保留兼容参数，无实际效果。
`file_resource.type` 当前固定为 `NULL`（后续由模型解析回填），`--doc-type` 仅保留兼容参数。

