# GCP DevOps Project — Cloud Run CI/CD

Personal portfolio project — independent, not affiliated with any employer.
One repo, one pipeline, one story: **GitHub push → Cloud Build → Artifact Registry → Cloud Run, Terraform-managed, with one SLO + alert in Cloud Monitoring.**

App: a small FastAPI capacity-estimator API (`GET /health`, `POST /estimate`), reusing the capacity math from the Azure Capacity Planner — worked examples only, no live Azure data, no credentials in code.

## What you build
- FastAPI app + Dockerfile (`app/`, `Dockerfile`)
- Cloud Build pipeline (`cloudbuild.yaml`): build → push image → deploy to Cloud Run
- Terraform (`terraform/`): Artifact Registry, Cloud Run service, Secret Manager, required APIs
- Observability (do in the console after first deploy): one SLO for the Cloud Run service + one alert on error rate / latency, then trigger it and triage from Cloud Logging

## Cost guardrails — read first
- Use the $300 / 90-day trial credit. **Cloud SQL has no Always Free tier — it is NOT in this project.**
- Set a billing budget alert at $0 / $1 BEFORE you deploy anything. A budget alert only emails — it does not stop spending. The real guardrail is: `terraform destroy` / delete the Cloud Run service after each lab session.
- Cloud Run + Artifact Registry for this tiny app should stay in free-tier / trial range if you delete after use. GKE is not used here.

## Day 1 — 30–45 min
1. Create a free GCP project at console.cloud.google.com (new project, note the Project ID).
2. Set a billing budget alert ($0 / $1) in Billing → Budgets & alerts.
3. Install `gcloud` CLI on your PC, then: `gcloud init` → pick the new project → `gcloud auth login`.
4. Clone this repo (once pushed to GitHub) and run the app locally:
   ```
   pip install -r app/requirements.txt
   uvicorn app.main:app --host 0.0.0.0 --port 8080
   ```
   Check http://localhost:8080/health — expect `{"status":"ok"}`
   Then test: `POST /estimate` with `{"current_size_gb": 1000, "monthly_growth_pct": 5}` — expect 12m = 1795.86 GB, with 20% headroom = 2155.03 GB.
5. Day 1 proof, say it out loud: "I created a GCP project, set a budget alert, installed gcloud, and ran the estimator locally."

## Day 2 — Terraform + first Cloud Run deploy
1. `cd terraform && terraform init && terraform plan -var="project_id=YOUR_PROJECT_ID"`
2. `terraform apply` (creates Artifact Registry, Cloud Run, Secret Manager).
3. Build + push + deploy once manually, or set up the Cloud Build trigger (see below), then visit the service URL and hit `/health`.

## Day 3 — Cloud Build trigger (the CI/CD part)
1. In Cloud Build → Triggers, connect your GitHub repo, trigger on push to `main`.
2. Substitutions: `_REGION=us-central1`, `_REPO=capacity-estimator`, `_SERVICE=capacity-estimator`.
3. Push a small change (e.g. a comment), watch Cloud Build run, then check the new Cloud Run revision.

## Day 4 — SLO + alert + rollback
1. In Cloud Monitoring, create one SLO for the Cloud Run service (e.g. 99% availability, 30-day window) and one alert.
2. Break it on purpose: deploy a bad revision, watch the alert, triage in Cloud Logging, then roll back in Cloud Run (previous revision → deploy).
3. `terraform destroy` when done. Delete the Artifact Registry images if you want a clean slate.

## Interview story (3 lines, spoken cold)
"I built a capacity-estimator API on GCP: GitHub push triggers Cloud Build, which builds and pushes the image to Artifact Registry and deploys to Cloud Run, all Terraform-managed with secrets in Secret Manager. I defined an SLO in Cloud Monitoring, got paged by my own alert, triaged it from logs, and rolled back. It's hands-on project work on GCP — my production experience is on Azure."

## Honest framing
- Hands-on GCP project work, not production GCP experience.
- No live Azure data, no subscription, no company code.
- Exam note: this project covers the hands-on part of the Professional Cloud DevOps Engineer path. The Nov 23, 2026 exam guide is the one to study for Phase 2 — it names MCP servers, Cloud Deploy, Infrastructure Manager, and token-consumption optimisation.
