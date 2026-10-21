import json
import os
import uuid
from fastapi import FastAPI, HTTPException, status
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import redis

app = FastAPI(title="Mini Sourcing Engine")

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))

redis_client = redis.Redis(
    host=REDIS_HOST,
    port=REDIS_PORT,
    socket_connect_timeout=2,
    socket_timeout=2,
    decode_responses=True,
)


class ResumeItem(BaseModel):
    id: str
    name: str
    skills: list[str]
    years_experience: int
    summary: str


class JobCreateRequest(BaseModel):
    job_description: str = Field(..., max_length=5000)
    resumes: list[ResumeItem] = Field(..., max_length=500)


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


@app.post("/jobs", status_code=status.HTTP_202_ACCEPTED)
def create_job(request: JobCreateRequest):
    job_id = str(uuid.uuid4())
    job_key = f"job:{job_id}"
    payload_json = json.dumps(
        request.model_dump() if hasattr(request, "model_dump") else request.dict()
    )

    try:
        pipe = redis_client.pipeline()
        pipe.hset(job_key, mapping={"status": "queued", "payload": payload_json})
        pipe.rpush("queue:ranking", job_id)
        pipe.expire(job_key, 86400)
        pipe.execute()
    except Exception:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"detail": "Redis is unreachable"},
        )

    return {"job_id": job_id, "status": "queued"}


@app.get("/jobs/{job_id}")
def get_job(job_id: str):
    try:
        raw_data = redis_client.hgetall(f"job:{job_id}")
    except Exception:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={"detail": "Redis is unreachable"},
        )

    if not raw_data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Job not found",
        )

    job_data = {
        k.decode("utf-8") if isinstance(k, bytes) else k: (
            v.decode("utf-8") if isinstance(v, bytes) else v
        )
        for k, v in raw_data.items()
    }

    response = {
        "job_id": job_id,
        "status": job_data.get("status"),
    }

    if "result" in job_data and job_data["result"]:
        try:
            response["result"] = json.loads(job_data["result"])
        except (json.JSONDecodeError, TypeError):
            response["result"] = job_data["result"]

    if "error" in job_data and job_data["error"] is not None:
        response["error"] = job_data["error"]

    return response
