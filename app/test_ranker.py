import pytest
from ranker import rank


def test_empty_job_description():
    resumes = [
        {
            "id": "C002",
            "name": "Synthetic Candidate 002",
            "skills": ["Docker"],
            "summary": "Docker expert.",
        },
        {
            "id": "C001",
            "name": "Synthetic Candidate 001",
            "skills": ["Python"],
            "summary": "Python developer.",
        },
    ]
    # Empty string
    results = rank("", resumes)
    assert len(results) == 2
    assert results[0] == {"id": "C001", "name": "Synthetic Candidate 001", "score": 0.0}
    assert results[1] == {"id": "C002", "name": "Synthetic Candidate 002", "score": 0.0}

    # Whitespace only
    results_ws = rank("    ", resumes)
    assert len(results_ws) == 2
    assert results_ws[0]["score"] == 0.0
    assert results_ws[1]["score"] == 0.0


def test_no_matching_skills():
    resumes = [
        {
            "id": "C002",
            "name": "Synthetic Candidate 002",
            "skills": ["Docker", "Kubernetes"],
            "summary": "DevOps pro.",
        },
        {
            "id": "C001",
            "name": "Synthetic Candidate 001",
            "skills": ["Linux", "Bash"],
            "summary": "SysAdmin specialist.",
        },
    ]
    results = rank("Ruby Rails Elixir", resumes)
    assert len(results) == 2
    # All scores should be 0.0
    assert results[0]["score"] == 0.0
    assert results[1]["score"] == 0.0
    # Ties broken by id
    assert results[0]["id"] == "C001"
    assert results[1]["id"] == "C002"


def test_ordering():
    resumes = [
        {
            "id": "C001",
            "name": "Candidate Low",
            "skills": ["Docker"],
            "summary": "Junior engineer.",
        },
        {
            "id": "C002",
            "name": "Candidate High",
            "skills": ["Docker", "Kubernetes", "Terraform"],
            "summary": "Senior cloud engineer.",
        },
        {
            "id": "C003",
            "name": "Candidate Mid",
            "skills": ["Docker", "Kubernetes"],
            "summary": "Mid-level engineer.",
        },
    ]
    # 3 keywords in JD
    job_description = "Docker Kubernetes Terraform"
    results = rank(job_description, resumes)

    assert len(results) == 3
    assert [r["id"] for r in results] == ["C002", "C003", "C001"]
    assert results[0]["score"] == pytest.approx(1.0)
    assert results[1]["score"] == pytest.approx(2 / 3)
    assert results[2]["score"] == pytest.approx(1 / 3)


def test_ties():
    resumes = [
        {
            "id": "C003",
            "name": "Candidate 003",
            "skills": ["Docker"],
            "summary": "Cloud engineer.",
        },
        {
            "id": "C001",
            "name": "Candidate 001",
            "skills": ["Docker"],
            "summary": "Cloud engineer.",
        },
        {
            "id": "C002",
            "name": "Candidate 002",
            "skills": ["Docker"],
            "summary": "Cloud engineer.",
        },
    ]
    # All three match 1/1 keyword
    results = rank("Docker", resumes)
    assert len(results) == 3
    assert [r["id"] for r in results] == ["C001", "C002", "C003"]
    assert all(r["score"] == 1.0 for r in results)


def test_top_n_limit():
    resumes = [
        {
            "id": f"C{i:03d}",
            "name": f"Synthetic Candidate {i:03d}",
            "skills": ["Docker"],
            "summary": "DevOps engineer.",
        }
        for i in range(1, 21)
    ]

    # Default top_n is 10
    results_default = rank("Docker", resumes)
    assert len(results_default) == 10
    assert results_default[0]["id"] == "C001"
    assert results_default[-1]["id"] == "C010"

    # Custom top_n = 5
    results_5 = rank("Docker", resumes, top_n=5)
    assert len(results_5) == 5
    assert results_5[0]["id"] == "C001"
    assert results_5[-1]["id"] == "C005"

    # Custom top_n = 0
    results_0 = rank("Docker", resumes, top_n=0)
    assert len(results_0) == 0

    # Custom top_n exceeding candidate list length
    results_exceed = rank("Docker", resumes[:3], top_n=10)
    assert len(results_exceed) == 3


def test_keyword_matching_in_summary_and_skills():
    resumes = [
        {
            "id": "C001",
            "name": "Candidate 001",
            "skills": ["Docker"],
            "summary": "Extensive experience with Prometheus and Grafana monitoring.",
        }
    ]
    # "Docker" is in skills, "Prometheus" and "Grafana" are in summary
    results = rank("Docker Prometheus Grafana", resumes)
    assert len(results) == 1
    assert results[0]["score"] == pytest.approx(1.0)
    assert set(results[0].keys()) == {"id", "name", "score"}
