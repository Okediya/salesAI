from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from backend.app.core.database import get_db
from backend.app.models.db_models import Product, Lead, Campaign, Interaction, ActivityLog, AgentState, LeadStatus, CampaignStatus, AutonomyMode
from backend.app.models.schemas import DashboardStatsResponse, AgentStateResponse, AgentControlRequest, ActivityLogResponse, ProductCreate
from backend.app.engine.taskmaster_loop import taskmaster_engine
from backend.app.agents.orchestrator import orchestrator

router = APIRouter(prefix="/agent", tags=["24/7 TaskMaster Agent Engine"])

@router.get("/stats", response_model=DashboardStatsResponse)
def get_dashboard_stats(db: Session = Depends(get_db)):
    active_product = db.query(Product).filter(Product.is_active == True).first()
    
    total_leads = db.query(Lead).count()
    discovered_leads = db.query(Lead).filter(Lead.status == LeadStatus.DISCOVERED).count()
    contacted_leads = db.query(Lead).filter(Lead.status == LeadStatus.CONTACTED).count()
    engaged_leads = db.query(Lead).filter(Lead.status == LeadStatus.ENGAGED).count()
    qualified_leads = db.query(Lead).filter(Lead.status == LeadStatus.QUALIFIED).count()
    won_leads = db.query(Lead).filter(Lead.status == LeadStatus.WON).count()
    total_campaigns_sent = db.query(Campaign).filter(Campaign.status == CampaignStatus.SENT).count()

    avg_intent_result = db.query(func.avg(Interaction.intent_score)).scalar()
    avg_intent = round(float(avg_intent_result), 1) if avg_intent_result else 78.5

    state = db.query(AgentState).first()
    if not state:
        state_resp = AgentStateResponse(
            is_running=taskmaster_engine.is_running,
            autonomy_mode=taskmaster_engine.autonomy_mode,
            cycle_interval=taskmaster_engine.cycle_interval,
            cycles_completed=0,
            last_cycle_at=None,
            current_task=taskmaster_engine.current_task
        )
    else:
        state_resp = AgentStateResponse(
            is_running=taskmaster_engine.is_running,
            autonomy_mode=taskmaster_engine.autonomy_mode,
            cycle_interval=state.cycle_interval,
            cycles_completed=state.cycles_completed,
            last_cycle_at=state.last_cycle_at,
            current_task=taskmaster_engine.current_task
        )

    recent_logs = db.query(ActivityLog).order_by(ActivityLog.created_at.desc()).limit(15).all()

    return DashboardStatsResponse(
        total_leads=total_leads,
        discovered_leads=discovered_leads,
        contacted_leads=contacted_leads,
        engaged_leads=engaged_leads,
        qualified_leads=qualified_leads,
        won_leads=won_leads,
        total_campaigns_sent=total_campaigns_sent,
        average_intent_score=avg_intent,
        agent_state=state_resp,
        active_product=active_product,
        recent_activities=recent_logs
    )

@router.get("/state", response_model=AgentStateResponse)
def get_agent_state(db: Session = Depends(get_db)):
    state = db.query(AgentState).first()
    if not state:
        return AgentStateResponse(
            is_running=taskmaster_engine.is_running,
            autonomy_mode=taskmaster_engine.autonomy_mode,
            cycle_interval=taskmaster_engine.cycle_interval,
            cycles_completed=0,
            last_cycle_at=None,
            current_task=taskmaster_engine.current_task
        )
    return AgentStateResponse(
        is_running=taskmaster_engine.is_running,
        autonomy_mode=taskmaster_engine.autonomy_mode,
        cycle_interval=state.cycle_interval,
        cycles_completed=state.cycles_completed,
        last_cycle_at=state.last_cycle_at,
        current_task=taskmaster_engine.current_task
    )

@router.post("/control")
async def control_agent(req: AgentControlRequest, db: Session = Depends(get_db)):
    action = req.action.upper()
    if action == "START":
        await taskmaster_engine.start()
    elif action == "PAUSE":
        await taskmaster_engine.stop()
    elif action == "TRIGGER_CYCLE":
        await taskmaster_engine.run_single_cycle()
    elif action == "SET_MODE":
        if req.autonomy_mode:
            taskmaster_engine.autonomy_mode = req.autonomy_mode
        if req.cycle_interval:
            taskmaster_engine.cycle_interval = req.cycle_interval
    else:
        raise HTTPException(status_code=400, detail=f"Unknown action {req.action}")

    return {"message": f"Action '{action}' executed successfully", "is_running": taskmaster_engine.is_running, "mode": taskmaster_engine.autonomy_mode.value}

@router.get("/logs", response_model=List[ActivityLogResponse])
def get_activity_logs(limit: int = 50, db: Session = Depends(get_db)):
    return db.query(ActivityLog).order_by(ActivityLog.created_at.desc()).limit(limit).all()

@router.post("/seed-demo")
async def seed_demo_data(db: Session = Depends(get_db)):
    """
    1-Click Seed for instant Hackathon Judges Demo.
    Seeds a high-tech product ('DevPulse AI: Autonomous Continuous Code Intelligence')
    and runs full multi-agent prospecting, copy generation, and outreach cycles.
    """
    sample_product = ProductCreate(
        name="DevPulse AI",
        tagline="Autonomous Codebase Intelligence & Continuous Security Sentry",
        description="DevPulse AI autonomously scans B2B enterprise repositories, auto-detects performance regressions, generates verified PR fixes, and optimizes CI/CD pipeline costs.",
        website_url="https://devpulse.ai",
        target_market="Series A-D B2B tech companies with 20-500 engineers",
        pricing_model="$299/mo per team + Enterprise custom tier",
        value_propositions="Cuts CI/CD compute costs by 40%, eliminates 90% of manual code review bottlenecks, autonomous 24/7 security scanning."
    )

    product = await orchestrator.onboard_product(db, sample_product)
    
    # Run initial prospecting cycle
    leads = await orchestrator.execute_prospecting_cycle(db, product.id, batch_size=4)
    
    # Generate copy for first 2 leads
    for lead in leads[:2]:
        await orchestrator.execute_campaign_generation(db, lead.id)

    return {"message": "Demo data seeded successfully!", "product_id": product.id, "leads_created": len(leads)}

@router.post("/chat")
async def chat_with_sales_agent(
    req: dict,
    db: Session = Depends(get_db)
):
    """
    Conversational AI interface. Interacts naturally with the user, collects product & contact info,
    finds leads, writes ads, and runs daily follow-ups.
    """
    from backend.app.agents.conversational_agent import conversational_agent
    
    user_msg = req.get("message", "")
    history = req.get("history", [])
    
    if not user_msg:
        raise HTTPException(status_code=400, detail="Message cannot be empty")
        
    result = await conversational_agent.handle_user_message(db, user_msg, history)
    return result

