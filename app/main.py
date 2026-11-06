"""GCP DevOps project — Cloud Run capacity estimator API.

Personal portfolio project — independent, not affiliated with any employer.
Small FastAPI app, reused capacity math from the Azure Capacity Planner
(worked examples only, no live Azure data, no credentials in code).
Endpoints: GET /health, POST /estimate
"""
from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(title="capacity-estimator", version="1.0.0")


class EstimateRequest(BaseModel):
    current_size_gb: float = Field(gt=0)
    monthly_growth_pct: float = Field(ge=0)
    target_headroom_pct: float = Field(default=20.0, ge=0)


@app.get("/health")
def health():
    return {"status": "ok", "service": "capacity-estimator"}


@app.post("/estimate")
def estimate(req: EstimateRequest):
    g = 1 + req.monthly_growth_pct / 100.0
    proj = {f"{m}m": round(req.current_size_gb * g ** m, 2) for m in (3, 6, 12)}
    twelve = proj["12m"]
    with_headroom = round(twelve * (1 + req.target_headroom_pct / 100.0), 2)
    return {
        "current_size_gb": req.current_size_gb,
        "monthly_growth_pct": req.monthly_growth_pct,
        "projected_gb": proj,
        "recommended_capacity_gb_12m_with_headroom": with_headroom,
        "target_headroom_pct": req.target_headroom_pct,
        "note": "Planning calculation only. Does not read or resize any live resource.",
    }
