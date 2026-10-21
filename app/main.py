import os
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
import redis

app = FastAPI(title="Mini Sourcing Engine")

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    socket_connect_timeout=2,
    socket_timeout=2,
)


@app.get("/health")
def health():
    try:
        if redis_client.ping():
            return {"status": "ok", "redis": "ok"}
    except Exception:
        pass

    return JSONResponse(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        content={"status": "degraded", "redis": "down"},
    )
