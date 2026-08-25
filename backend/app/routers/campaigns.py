from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
import datetime
from backend.app.core.database import get_db
from backend.app.models.db_models import Campaign, CampaignStatus, Lead, LeadStatus
from backend.app.models.schemas import CampaignResponse

router = APIRouter(prefix="/campaigns", tags=["Campaigns & Outreach"])

@router.get("/", response_model=List[CampaignResponse])
def list_campaigns(
    lead_id: Optional[int] = None,
    status: Optional[CampaignStatus] = None,
    db: Session = Depends(get_db)
):
    query = db.query(Campaign)
    if lead_id:
        query = query.filter(Campaign.lead_id == lead_id)
    if status:
        query = query.filter(Campaign.status == status)
    return query.order_by(Campaign.created_at.desc()).all()

@router.post("/{campaign_id}/dispatch", response_model=CampaignResponse)
def dispatch_campaign(campaign_id: int, db: Session = Depends(get_db)):
    """Manually dispatches a drafted outreach campaign."""
    campaign = db.query(Campaign).filter(Campaign.id == campaign_id).first()
    if not campaign:
        raise HTTPException(status_code=404, detail="Campaign not found")
    
    campaign.status = CampaignStatus.SENT
    campaign.sent_at = datetime.datetime.utcnow()
    
    if campaign.lead and campaign.lead.status == LeadStatus.DISCOVERED:
        campaign.lead.status = LeadStatus.CONTACTED

    db.commit()
    db.refresh(campaign)
    return campaign
