import re


def rank(job_description: str, resumes: list[dict], top_n: int = 10) -> list[dict]:
    """
    Scores each resume by the fraction of job-description keywords found
    in the resume's skills and summary, and returns the top_n sorted by score
    descending, with ties broken by id ascending.
    """
    keywords = set(re.findall(r"[a-zA-Z0-9]+", job_description.lower()))
    num_keywords = len(keywords)

    scored_resumes = []
    for resume in resumes:
        r_id = resume.get("id")
        r_name = resume.get("name")

        if num_keywords == 0:
            score = 0.0
        else:
            skills = resume.get("skills", [])
            skills_text = " ".join(skills) if isinstance(skills, list) else str(skills)
            summary_text = resume.get("summary", "")
            combined_text = f"{skills_text} {summary_text}".lower()
            resume_tokens = set(re.findall(r"[a-zA-Z0-9]+", combined_text))

            matched = keywords & resume_tokens
            score = len(matched) / num_keywords

        scored_resumes.append({
            "id": r_id,
            "name": r_name,
            "score": score,
        })

    # Sort descending by score, ties broken by id ascending
    scored_resumes.sort(
        key=lambda item: (
            -item["score"],
            str(item["id"] if item["id"] is not None else ""),
        )
    )

    if top_n <= 0:
        return []
    return scored_resumes[:top_n]
