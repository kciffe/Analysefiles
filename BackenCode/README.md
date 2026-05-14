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
ssh -N -L 18081:127.0.0.1:8081 -p 10711 root@10.0.6.135
uv run uvicorn src.api.main:app --reload --env-file .env

```

## 批量导入文档到三张表
启动参数第一个位置为输入目录路径：
```bash
uv run python -m src.scripts.batch_import_docs "D:\\8\Desktop\\论文\\paper\\over" --source arxiv
uv run python -m src.scripts.batch_import_docs "D:\\8\\Desktop\\论文\\Tongyi" --source arxiv  
```

常用参数：
```bash
--extensions .pdf,.docx,.md
--source arxiv
--doc-type arxiv
--publish-venue "arXiv预印本"
--overwrite
```

## 服务器洞穿代理
```ssh
ssh -N -R 17890:127.0.0.1:7890 root@10.0.6.135
ssh -N -R 127.0.0.1:17890:127.0.0.1:7890 -L 1455:127.0.0.1:1455 root@10.0.6.135
```

