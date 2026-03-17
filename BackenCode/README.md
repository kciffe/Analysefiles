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
uv run uvicorn src.api.main:app --reload
```# deepresearch

