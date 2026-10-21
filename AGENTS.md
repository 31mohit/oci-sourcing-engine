# Mini Sourcing Engine on OCI

## Goal

A deliberately thin candidate-ranking app, run like a production system on Oracle Cloud (OCI) to show Cloud Operations skills. The operations layer is the real deliverable. Full requirements are in docs/PRD.md; read it before starting any task.

## Stack

FastAPI, Redis, Docker Compose, Terraform on OCI, GitHub Actions, Prometheus and Grafana. OCI Always Free tier only.

## Rules

- Synthetic data only. No real candidate data or PII anywhere.
- Never put secrets, keys or credentials in any file. Use OCI Vault or environment variables. Never commit .oci/, _.pem, _.tfvars or \*.tfstate.
- Keep the app thin. Prioritise infrastructure, monitoring, reliability, security and documentation.
- The OCI Always Free VMs are Arm (linux/arm64). Build container images for that architecture.
- Follow the phases in section 8 of docs/PRD.md in order. Do not skip ahead.
- No claims of ranking accuracy or fairness. A human approves every decision.
- Stay within US$0 cost.
