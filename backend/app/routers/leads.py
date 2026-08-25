from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from backend.app.core.database import get_db
from backend.app.models.db_models import Lead, LeadStatus, Product, Campaign, CampaignStatus, ChannelType
from backend.app.models.schemas import LeadCreate, LeadResponse, LeadStatusUpdate, SdrAnalysisResult, DeliveryResult
from backend.app.agents.orchestrator import orchestrator
from backend.app.engine.taskmaster_loop import taskmaster_engine
from backend.app.services.delivery_service import delivery_service

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

@router.post("/", response_model=LeadResponse)
async def create_custom_lead(lead_in: LeadCreate, db: Session = Depends(get_db)):
    """
    Creates a custom test lead (e.g. user adding themselves) and optionally auto-generates outreach.
    """
    # Get active product or first product
    active_product = db.query(Product).filter(Product.is_active == True).first()
    if not active_product:
        active_product = db.query(Product).first()
    
    if not active_product:
        raise HTTPException(
            status_code=400,
            detail="No product found. Please onboard your startup/product first in the Product Setup tab."
        )

    lead = Lead(
        product_id=active_product.id,
        name=lead_in.name,
        company=lead_in.company,
        role=lead_in.role or "Founder & CEO",
        email=lead_in.email,
        phone_number=lead_in.phone_number,
        telegram_handle=lead_in.telegram_handle,
        linkedin_url=lead_in.linkedin_url,
        confidence_score=0.98,
        status=LeadStatus.DISCOVERED,
        pain_points=lead_in.pain_points or f"Scaling {lead_in.company} pipeline efficiently without manual sales friction",
        personalization_hooks=lead_in.personalization_hooks or f"Active leadership at {lead_in.company}",
        is_approved=True
    )
    db.add(lead)
    db.commit()
    db.refresh(lead)

    # Broadcast event to frontend
    await taskmaster_engine.broadcast_event("NEW_LEAD_DISCOVERED", {
        "id": lead.id,
        "name": lead.name,
        "company": lead.company,
        "role": lead.role
    })

    # Auto generate outreach campaign sequence if requested
    if lead_in.auto_generate_campaign:
        await orchestrator.execute_campaign_generation(db, lead.id)

    db.refresh(lead)
    return lead

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

@router.post("/{lead_id}/dispatch-email", response_model=DeliveryResult)
async def dispatch_lead_email(lead_id: int, db: Session = Depends(get_db)):
    """Dispatches the generated email outreach to the lead's email address."""
    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")
    if not lead.email:
        raise HTTPException(status_code=400, detail="Lead does not have an email address configured.")

    # Find the primary email campaign step
    campaign = db.query(Campaign).filter(
        Campaign.lead_id == lead_id,
        Campaign.channel == ChannelType.EMAIL
    ).order_by(Campaign.sequence_step.asc()).first()

    subject = campaign.subject if campaign else f"Question regarding {lead.company}"
    body = campaign.body if campaign else f"Hi {lead.name},\n\nWanted to reach out to connect regarding {lead.company}."

    result = await delivery_service.dispatch_email(
        to_email=lead.email,
        subject=subject,
        body=body,
        lead_name=lead.name
    )

    if campaign and result.get("success"):
        campaign.status = CampaignStatus.SENT
        campaign.sent_at = datetime.utcnow()
        lead.status = LeadStatus.CONTACTED
        db.commit()

        await taskmaster_engine.broadcast_event("CAMPAIGN_DISPATCHED", {
            "lead_id": lead.id,
            "channel": "EMAIL",
            "recipient": lead.email
        })

    return DeliveryResult(
        success=result.get("success", False),
        channel="EMAIL",
        recipient=lead.email,
        message=result.get("message", "Email processed"),
        action_url=result.get("action_url")
    )

@router.post("/{lead_id}/dispatch-whatsapp", response_model=DeliveryResult)
async def dispatch_lead_whatsapp(lead_id: int, db: Session = Depends(get_db)):
    """Dispatches or prepares the WhatsApp outreach message for the lead."""
    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")
    if not lead.phone_number:
        raise HTTPException(status_code=400, detail="Lead does not have a phone/WhatsApp number configured.")

    # Find the WhatsApp or primary campaign
    campaign = db.query(Campaign).filter(
        Campaign.lead_id == lead_id,
        Campaign.channel == ChannelType.WHATSAPP
    ).first()

    if not campaign:
        campaign = db.query(Campaign).filter(Campaign.lead_id == lead_id).first()

    body = campaign.body if campaign else f"Hi {lead.name} 👋 Reaching out to see if you're open to exploring how we can help {lead.company} scale sales pipeline automatically."

    result = await delivery_service.dispatch_whatsapp(
        phone_number=lead.phone_number,
        message=body,
        lead_name=lead.name
    )

    if campaign and result.get("success"):
        campaign.status = CampaignStatus.SENT
        campaign.sent_at = datetime.utcnow()
        lead.status = LeadStatus.CONTACTED
        db.commit()

        await taskmaster_engine.broadcast_event("CAMPAIGN_DISPATCHED", {
            "lead_id": lead.id,
            "channel": "WHATSAPP",
            "recipient": lead.phone_number
        })

    return DeliveryResult(
        success=result.get("success", True),
        channel="WHATSAPP",
        recipient=lead.phone_number,
        message=result.get("message", "WhatsApp ready"),
        action_url=result.get("action_url")
    )

@router.post("/{lead_id}/dispatch-telegram", response_model=DeliveryResult)
async def dispatch_lead_telegram(lead_id: int, db: Session = Depends(get_db)):
    """Dispatches or prepares the Telegram outreach message for the lead."""
    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")
    if not lead.telegram_handle and not lead.phone_number:
        raise HTTPException(status_code=400, detail="Lead does not have a Telegram handle or phone number configured.")

    # Find the Telegram campaign or fallback
    campaign = db.query(Campaign).filter(
        Campaign.lead_id == lead_id,
        Campaign.channel == ChannelType.TELEGRAM
    ).first()

    if not campaign:
        campaign = db.query(Campaign).filter(Campaign.lead_id == lead_id).first()

    body = campaign.body if campaign else f"Hi {lead.name} 👋 Saw your work at {lead.company}! Open to seeing how we help teams scale revenue with autonomous 24/7 agents?"

    product = db.query(Product).filter(Product.id == lead.product_id).first()
    bot_token = product.telegram_bot_token if product else None

    result = await delivery_service.dispatch_telegram(
        telegram_handle=lead.telegram_handle or lead.phone_number,
        message=body,
        lead_name=lead.name,
        bot_token=bot_token
    )

    if campaign and result.get("success"):
        campaign.status = CampaignStatus.SENT
        campaign.sent_at = datetime.utcnow()
        lead.status = LeadStatus.CONTACTED
        db.commit()

        await taskmaster_engine.broadcast_event("CAMPAIGN_DISPATCHED", {
            "lead_id": lead.id,
            "channel": "TELEGRAM",
            "recipient": lead.telegram_handle or lead.phone_number
        })

    return DeliveryResult(
        success=result.get("success", True),
        channel="TELEGRAM",
        recipient=lead.telegram_handle or lead.phone_number or "Telegram",
        message=result.get("message", "Telegram pitch ready"),
        action_url=result.get("action_url")
    )

@router.post("/{lead_id}/inbound")
async def handle_inbound_lead_message(
    lead_id: int,
    request: dict,
    db: Session = Depends(get_db)
):
    """
    Receives an incoming message from a lead (e.g. from Telegram/Email/Chatbot),
    runs SdrAgent with continuous product knowledge, updates pipeline status,
    and optionally auto-dispatches the counter-response.
    """
    incoming_msg = request.get("message")
    if not incoming_msg:
        raise HTTPException(status_code=400, detail="Message is required")

    channel = request.get("channel", "TELEGRAM").upper()
    auto_dispatch = request.get("auto_dispatch_reply", True)

    lead = db.query(Lead).filter(Lead.id == lead_id).first()
    if not lead:
        raise HTTPException(status_code=404, detail="Lead not found")

    # Run SDR agent analysis with continuous knowledge base
    analysis = await orchestrator.execute_sdr_reply_handling(db, lead_id, incoming_msg)

    dispatch_res = None
    if auto_dispatch:
        if channel == "TELEGRAM" and (lead.telegram_handle or lead.phone_number):
            product = db.query(Product).filter(Product.id == lead.product_id).first()
            dispatch_res = await delivery_service.dispatch_telegram(
                telegram_handle=lead.telegram_handle or lead.phone_number,
                message=analysis.suggested_reply,
                lead_name=lead.name,
                bot_token=product.telegram_bot_token if product else None
            )
        elif channel == "EMAIL" and lead.email:
            dispatch_res = await delivery_service.dispatch_email(
                to_email=lead.email,
                subject=f"Re: Growth at {lead.company}",
                body=analysis.suggested_reply,
                lead_name=lead.name
            )

    return {
        "success": True,
        "lead_id": lead.id,
        "lead_name": lead.name,
        "sentiment": analysis.sentiment,
        "intent_score": analysis.intent_score,
        "objection_type": analysis.objection_type,
        "recommended_action": analysis.recommended_action,
        "agent_reply": analysis.suggested_reply,
        "dispatch_result": dispatch_res,
        "processed_at": datetime.utcnow()
    }

@router.post("/{lead_id}/simulate-reply", response_model=SdrAnalysisResult)
async def simulate_prospect_reply(
    lead_id: int,
    message: str = Query(..., description="Simulated incoming reply from prospect"),
    db: Session = Depends(get_db)
):
    """Triggers SdrAgent to analyze intent and produce objection-handling counter-response."""
    result = await orchestrator.execute_sdr_reply_handling(db, lead_id, message)
    return result


