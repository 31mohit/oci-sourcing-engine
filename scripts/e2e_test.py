import json
import os
from pathlib import Path
import sys
import time
from urllib.error import HTTPError, URLError
import urllib.request

BASE_URL = os.getenv("API_URL", "http://localhost:8000").rstrip("/")
FIXED_JOB_DESCRIPTION = (
    "Looking for a DevOps engineer with experience in Docker, Kubernetes, "
    "Terraform, Python, Linux, and CI/CD."
)


def make_request(url: str, method: str = "GET", data: dict | None = None) -> tuple[int, dict]:
    req_body = None
    headers = {}
    if data is not None:
        req_body = json.dumps(data).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url, data=req_body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = json.loads(resp.read().decode("utf-8"))
            return resp.status, body
    except HTTPError as e:
        err_body = e.read().decode("utf-8")
        try:
            body = json.loads(err_body)
        except Exception:
            body = {"raw": err_body}
        return e.code, body


def run_e2e_test() -> None:
    # 1. Check GET /health
    health_url = f"{BASE_URL}/health"
    try:
        status_code, body = make_request(health_url)
    except URLError as e:
        print(f"FAIL: /health connection error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"FAIL: Failed to check /health: {e}")
        sys.exit(1)

    if status_code != 200:
        print(f"FAIL: /health returned status code {status_code}, expected 200 (body: {body})")
        sys.exit(1)

    if body.get("status") != "ok" or body.get("redis") != "ok":
        print(f"FAIL: /health returned unexpected body: {body}")
        sys.exit(1)

    # 2. Load data/resumes.json
    repo_root = Path(__file__).resolve().parent.parent
    resumes_file = repo_root / "data" / "resumes.json"
    if not resumes_file.exists():
        print(f"FAIL: Resumes file not found at {resumes_file}")
        sys.exit(1)

    try:
        with open(resumes_file, "r", encoding="utf-8") as f:
            resumes = json.load(f)
    except Exception as e:
        print(f"FAIL: Failed to load {resumes_file}: {e}")
        sys.exit(1)

    if not isinstance(resumes, list) or len(resumes) == 0:
        print(f"FAIL: {resumes_file} contains no valid resumes")
        sys.exit(1)

    submitted_ids = {r.get("id") for r in resumes}

    # 3. Submit job via POST /jobs
    jobs_url = f"{BASE_URL}/jobs"
    payload = {
        "job_description": FIXED_JOB_DESCRIPTION,
        "resumes": resumes,
    }

    try:
        status_code, body = make_request(jobs_url, method="POST", data=payload)
    except URLError as e:
        print(f"FAIL: POST /jobs connection error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"FAIL: Failed to submit job via POST /jobs: {e}")
        sys.exit(1)

    if status_code != 202:
        print(f"FAIL: POST /jobs returned status code {status_code}, expected 202 (body: {body})")
        sys.exit(1)

    job_id = body.get("job_id")
    if not job_id:
        print(f"FAIL: POST /jobs response missing job_id (body: {body})")
        sys.exit(1)

    # 4. Poll GET /jobs/{id} for up to 30 seconds
    job_status_url = f"{BASE_URL}/jobs/{job_id}"
    start_time = time.time()
    final_job_data = None

    while time.time() - start_time <= 30:
        try:
            status_code, body = make_request(job_status_url)
        except Exception as e:
            print(f"FAIL: Error polling GET /jobs/{job_id}: {e}")
            sys.exit(1)

        if status_code != 200:
            print(f"FAIL: GET /jobs/{job_id} returned status {status_code} (body: {body})")
            sys.exit(1)

        current_status = body.get("status")
        if current_status == "done":
            final_job_data = body
            break
        elif current_status == "failed":
            print(f"FAIL: Job failed with error: {body.get('error', 'unknown error')}")
            sys.exit(1)

        time.sleep(1)

    if final_job_data is None:
        print(f"FAIL: Job {job_id} did not complete within 30 seconds")
        sys.exit(1)

    # 5. Assertions on the result
    status = final_job_data.get("status")
    if status != "done":
        print(f"FAIL: Expected status 'done', got '{status}'")
        sys.exit(1)

    result = final_job_data.get("result")
    if not isinstance(result, list):
        print(f"FAIL: Expected result to be a list, got {type(result)}")
        sys.exit(1)

    if len(result) > 10:
        print(f"FAIL: Result contains {len(result)} items, expected at most 10")
        sys.exit(1)

    for i in range(len(result) - 1):
        score_current = result[i].get("score", 0.0)
        score_next = result[i + 1].get("score", 0.0)
        if score_current < score_next:
            print(
                f"FAIL: Results not sorted descending by score: "
                f"item[{i}] score {score_current} < item[{i+1}] score {score_next}"
            )
            sys.exit(1)

    for item in result:
        item_id = item.get("id")
        if item_id not in submitted_ids:
            print(f"FAIL: Candidate id '{item_id}' not found in submitted resumes")
            sys.exit(1)

    print("PASS")
    sys.exit(0)


if __name__ == "__main__":
    run_e2e_test()
