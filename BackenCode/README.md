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

```# deepresearch

