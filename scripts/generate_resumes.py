import json
from pathlib import Path
import random

SKILLS_POOL = [
    "AWS",
    "Ansible",
    "Bash",
    "CI/CD",
    "Docker",
    "FastAPI",
    "Git",
    "GitHub Actions",
    "Grafana",
    "Kubernetes",
    "Linux",
    "Networking",
    "OCI",
    "PostgreSQL",
    "Prometheus",
    "Python",
    "Redis",
    "Terraform",
]


def generate_resumes(count: int = 50, seed: int = 42) -> list[dict]:
    random.seed(seed)
    resumes = []

    for i in range(1, count + 1):
        candidate_id = f"C{i:03d}"
        name = f"Synthetic Candidate {i:03d}"
        num_skills = random.randint(3, 6)
        skills = sorted(random.sample(SKILLS_POOL, num_skills))
        years_experience = random.randint(1, 12)
        summary = (
            f"Synthetic candidate with {years_experience} years of experience "
            f"specializing in {', '.join(skills)}."
        )

        resume = {
            "id": candidate_id,
            "name": name,
            "skills": skills,
            "years_experience": years_experience,
            "summary": summary,
        }
        resumes.append(resume)

    return resumes


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    output_dir = repo_root / "data"
    output_dir.mkdir(parents=True, exist_ok=True)
    output_file = output_dir / "resumes.json"

    resumes = generate_resumes(count=50, seed=42)

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(resumes, f, indent=2)
        f.write("\n")

    print(f"Generated {len(resumes)} synthetic resumes at {output_file}")


if __name__ == "__main__":
    main()
