import asyncio
import logging
import datetime
import random
from typing import Optional, List
from sqlalchemy.orm import Session
from backend.app.core.database import SessionLocal
from backend.app.models.db_models import (
    Product, Lead, Campaign, Interaction, ActivityLog, AgentState,
    AutonomyMode, LeadStatus, CampaignStatus, ChannelType
)
from backend.app.agents.orchestrator import orchestrator

logger = logging.getLogger(__name__)

# List of simulated realistic prospect inbound responses for the 24/7 autonomous loop
SIMULATED_REPLIES = [
    "Thanks for reaching out. We are currently evaluating solutions to scale our outbound efforts. What does your pricing structure look like?",
    "Hey, this looks really interesting. Can you send over a demo link or a quick 5-min walk-through video?",
    "Hi there. We're already using a combination of manual SDRs and another tool, but our conversion is underwhelming. How are you different?",
    "Sounds great, but our Q3 budget is pretty much locked right now. Is this something we could pilot at lower cost first?",
    "Hey! Perfect timing, our executive team was just discussing how to automate this exact workflow yesterday. Let's schedule a call."
]

class TaskMasterEngine:
    def __init__(self):
        self.is_running: bool = True
        self.autonomy_mode: AutonomyMode = AutonomyMode.AUTOPILOT
        self.cycle_interval: int = 25  # seconds for active demo
        self.current_task: str = "Initializing 24/7 TaskMaster Engine"
        self._task: Optional[asyncio.Task] = None
        self.ws_subscribers: List[any] = []

    def register_ws(self, ws):
        self.ws_subscribers.append(ws)

    def unregister_ws(self, ws):
        if ws in self.ws_subscribers:
            self.ws_subscribers.remove(ws)

    async def broadcast_event(self, event_type: str, data: dict):
        """Broadcasts real-time events to all connected Flutter frontends via WebSockets."""
        message = {
            "event": event_type,
            "timestamp": datetime.datetime.utcnow().isoformat(),
            "data": data
        }
        for ws in list(self.ws_subscribers):
            try:
                await ws.send_json(message)
            except Exception as e:
                logger.debug(f"Failed to send to WS client: {e}")
                self.unregister_ws(ws)

    async def start(self):
        if self._task and not self._task.done():
            return
        self.is_running = True
        self._task = asyncio.create_task(self._autonomous_loop())
        logger.info("24/7 TaskMaster Autonomous Engine started.")

    async def stop(self):
        self.is_running = False
        if self._task:
            self._task.cancel()
        logger.info("TaskMaster Autonomous Engine paused.")

    async def run_single_cycle(self):
        """Executes a single end-to-end autonomous cycle immediately."""
        db = SessionLocal()
        try:
            await self._execute_cycle(db)
        finally:
            db.close()

    async def _autonomous_loop(self):
        logger.info("Entering 24/7 autonomous loop...")
        while self.is_running:
            db = SessionLocal()
            try:
                await self._execute_cycle(db)
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Error during autonomous cycle execution: {e}", exc_info=True)
            finally:
                db.close()

            # Wait for next cycle
            await asyncio.sleep(self.cycle_interval)

    async def _execute_cycle(self, db: Session):
        # 1. Fetch active product
        active_product = db.query(Product).filter(Product.is_active == True).first()
        if not active_product:
            self.current_task = "Waiting for Product DNA Onboarding"
            return

        # 2. Update agent state in DB
        state = db.query(AgentState).first()
        if not state:
            state = AgentState(
                is_running=self.is_running,
                autonomy_mode=self.autonomy_mode,
                cycle_interval=self.cycle_interval,
                cycles_completed=0,
                current_task="Starting Cycle"
            )
            db.add(state)
        
        state.is_running = self.is_running
        state.autonomy_mode = self.autonomy_mode
        state.cycle_interval = self.cycle_interval
        state.cycles_completed += 1
        state.last_cycle_at = datetime.datetime.utcnow()

        cycle_num = state.cycles_completed
        logger.info(f"--- Running 24/7 Autonomous Cycle #{cycle_num} ---")

        # Step A: Check Lead Inventory (Discovery Phase)
        discovered_count = db.query(Lead).filter(
            Lead.product_id == active_product.id,
            Lead.status == LeadStatus.DISCOVERED
        ).count()

        if discovered_count < 3:
            self.current_task = "Prospecting New High-Intent Leads"
            state.current_task = self.current_task
            db.commit()

            new_leads = await orchestrator.execute_prospecting_cycle(
                db=db,
                product_id=active_product.id,
                batch_size=3
            )
            await self.broadcast_event("LEADS_DISCOVERED", {
                "count": len(new_leads),
                "leads": [{"id": l.id, "name": l.name, "company": l.company} for l in new_leads]
            })

        # Step B: Copywriting & Campaign Preparation
        leads_without_campaigns = db.query(Lead).filter(
            Lead.product_id == active_product.id,
            ~Lead.campaigns.any()
        ).limit(2).all()

        for lead in leads_without_campaigns:
            self.current_task = f"Generating Multichannel Copy for {lead.name}"
            state.current_task = self.current_task
            db.commit()

            campaigns = await orchestrator.execute_campaign_generation(db=db, lead_id=lead.id)
            await self.broadcast_event("CAMPAIGN_GENERATED", {
                "lead_id": lead.id,
                "lead_name": lead.name,
                "campaigns_count": len(campaigns)
            })

        # Step C: Outbound Dispatch (If AUTOPILOT)
        if self.autonomy_mode == AutonomyMode.AUTOPILOT:
            draft_campaigns = db.query(Campaign).filter(
                Campaign.product_id == active_product.id,
                Campaign.status == CampaignStatus.DRAFT
            ).limit(2).all()

            for camp in draft_campaigns:
                camp.status = CampaignStatus.SENT
                camp.sent_at = datetime.datetime.utcnow()
                camp.open_rate_sim = round(random.uniform(0.65, 0.95), 2)
                
                # Update lead status to CONTACTED
                if camp.lead and camp.lead.status == LeadStatus.DISCOVERED:
                    camp.lead.status = LeadStatus.CONTACTED

                orchestrator.log_activity(
                    db,
                    role="TaskMaster",
                    action=f"Dispatched {camp.channel.value} Sequence to {camp.lead.name if camp.lead else 'Prospect'}",
                    details=f"Subject: {camp.subject or 'Direct Message'}",
                    level="SUCCESS"
                )
                db.commit()
                
                await self.broadcast_event("CAMPAIGN_DISPATCHED", {
                    "campaign_id": camp.id,
                    "lead_id": camp.lead_id,
                    "channel": camp.channel.value
                })

        # Step D: Autonomous SDR Inbound Response Handling & Lead Qualification
        # Occasionally simulate high-intent inbound replies from contacted leads for live demo
        contacted_leads = db.query(Lead).filter(
            Lead.product_id == active_product.id,
            Lead.status == LeadStatus.CONTACTED
        ).all()

        if contacted_leads and random.random() < 0.6:
            target_lead = random.choice(contacted_leads)
            incoming_reply = random.choice(SIMULATED_REPLIES)

            self.current_task = f"SDR Handling Inbound Reply from {target_lead.name}"
            state.current_task = self.current_task
            db.commit()

            sdr_result = await orchestrator.execute_sdr_reply_handling(
                db=db,
                lead_id=target_lead.id,
                incoming_message=incoming_reply
            )

            await self.broadcast_event("REPLY_HANDLED", {
                "lead_id": target_lead.id,
                "lead_name": target_lead.name,
                "sentiment": sdr_result.sentiment,
                "intent_score": sdr_result.intent_score,
                "new_status": target_lead.status.value,
                "reply": sdr_result.suggested_reply
            })

        self.current_task = "Autonomous Monitoring Active"
        state.current_task = self.current_task
        db.commit()

        await self.broadcast_event("CYCLE_COMPLETED", {
            "cycle_number": state.cycles_completed,
            "timestamp": datetime.datetime.utcnow().isoformat()
        })

taskmaster_engine = TaskMasterEngine()
