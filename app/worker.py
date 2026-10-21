import json
import logging
import os
import time
import redis
from ranker import rank

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("worker")

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))


def get_redis_client() -> redis.Redis:
    return redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        socket_connect_timeout=2,
        socket_timeout=10,
        decode_responses=True,
    )


def process_job(redis_client: redis.Redis, job_id: str) -> None:
    job_key = f"job:{job_id}"
    start_time = time.perf_counter()

    job_data = redis_client.hgetall(job_key)
    if not job_data or "payload" not in job_data:
        logger.warning("Job %s no longer exists (expired), skipping.", job_id)
        return

    redis_client.hset(job_key, "status", "running")

    try:
        payload = json.loads(job_data["payload"])
        job_description = payload.get("job_description", "")
        resumes = payload.get("resumes", [])

        results = rank(job_description, resumes)

        redis_client.hset(
            job_key,
            mapping={
                "status": "done",
                "result": json.dumps(results),
            },
        )
        duration = time.perf_counter() - start_time
        logger.info("job_id=%s status=done duration=%.4fs", job_id, duration)
    except redis.RedisError:
        raise
    except Exception as exc:
        duration = time.perf_counter() - start_time
        error_msg = str(exc) or exc.__class__.__name__
        logger.error("Job %s failed: %s", job_id, error_msg)
        try:
            redis_client.hset(
                job_key,
                mapping={
                    "status": "failed",
                    "error": error_msg,
                },
            )
        except redis.RedisError:
            raise
        logger.info("job_id=%s status=failed duration=%.4fs", job_id, duration)


def run_worker() -> None:
    logger.info("Starting worker connecting to Redis at %s:%s", REDIS_HOST, REDIS_PORT)
    redis_client = get_redis_client()

    while True:
        try:
            popped = redis_client.blpop("queue:ranking", timeout=5)
            if not popped:
                continue

            _, job_id = popped
            process_job(redis_client, job_id)
        except redis.RedisError as exc:
            logger.error("Redis is unreachable: %s. Retrying in 2 seconds...", exc)
            time.sleep(2)
        except Exception as exc:
            logger.exception("Unexpected error in worker loop: %s", exc)
            time.sleep(1)


if __name__ == "__main__":
    run_worker()
