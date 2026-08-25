from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from backend.app.core.database import get_db
from backend.app.models.db_models import Lead, LeadStatus
from backend.app.models.schemas import LeadResponse, LeadStatusUpdate, SdrAnalysisResult
from backend.app.agents.orchestrator import orchestrator
from backend.app.engine.taskmaster_loop import taskmaster_engine

router = APIRouter(prefix="/leads", tags=["Leads & Pipeline"])

@router.get("/", response_model=List[LeadResponse])
def get_leads(
    status: Optional[LeadStatus] = None,
    product_id: Optional[int] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Lead)
    if product_id:
        query = query.filter(Lead.product_id == product_id)
    if status:
        query = query.filter(Lead.status == status)
    return query.order_by(Lead.updated_at.desc()).all()

@router.get("/{lead_id}", response_model=LeadResponse)
def get_lead(lead_id: int, db: Session = Depends(get_db)):
    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")
    return lead

@router.patch("/{lead_id}/status", response_model=LeadResponse)
async def update_lead_status(lead_id: int, update: LeadStatusUpdate, db: Session = Depends(get_db)):
    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")
    
    lead.status = update.status
    db.commit()
    db.refresh(lead)

    await taskmaster_engine.broadcast_event("LEAD_STATUS_CHANGED", {
        "lead_id": lead.id,
        "new_status": lead.status.value
    })
    return lead

@router.post("/{lead_id}/generate-campaign")
async def trigger_lead_campaign_generation(lead_id: int, db: Session = Depends(get_db)):
    """Triggers CopywriterAgent to generate tailored outreach for a specific lead."""
    campaigns = await orchestrator.execute_campaign_generation(db, lead_id)
    return {"message": f"Generated {len(campaigns)} outreach sequence steps", "count": len(campaigns)}

@router.post("/{lead_id}/simulate-reply", response_model=SdrAnalysisResult)
async def simulate_prospect_reply(
    lead_id: int,
    message: str = Query(..., description="Simulated incoming reply from prospect"),
    db: Session = Depends(get_db)
):
    """Triggers SdrAgent to analyze intent and produce objection-handling counter-response."""
    result = await orchestrator.execute_sdr_reply_handling(db, lead_id, message)
    return result
