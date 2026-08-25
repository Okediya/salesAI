import logging
import json
from typing import List, Optional
from sqlalchemy.orm import Session
from backend.app.agents.strategy_agent import strategy_agent
from backend.app.agents.prospector_agent import prospector_agent
from backend.app.agents.copywriter_agent import copywriter_agent
from backend.app.agents.sdr_agent import sdr_agent
from backend.app.models.db_models import Product, Lead, Campaign, Interaction, ActivityLog, LeadStatus, CampaignStatus, ChannelType
from backend.app.models.schemas import ProductCreate, SdrAnalysisResult

logger = logging.getLogger(__name__)

class AgentOrchestrator:
    def __init__(self):
        self.strategy_agent = strategy_agent
        self.prospector_agent = prospector_agent
        self.copywriter_agent = copywriter_agent
        self.sdr_agent = sdr_agent

    def log_activity(self, db: Session, role: str, action: str, details: str = "", level: str = "INFO"):
        activity = ActivityLog(
            agent_role=role,
            action=action,
            details=details,
            level=level
        )
        db.add(activity)
        db.commit()
        db.refresh(activity)
        return activity

    async def onboard_product(self, db: Session, product_in: ProductCreate) -> Product:
        """
        Step 1: Strategic Onboarding
        Runs StrategyAgent to parse Product DNA and extract target personas and ICP.
        """
        self.log_activity(
            db,
            role="StrategyAgent",
            action=f"Analyzing Product DNA for '{product_in.name}'",
            details="Extracting value propositions, target roles, and market hooks...",
            level="INFO"
        )
        
        analysis = await self.strategy_agent.analyze_product(product_in)

        # Deactivate older products for clear active context
        db.query(Product).update({Product.is_active: False})

        db_product = Product(
            name=product_in.name,
            tagline=product_in.tagline,
            description=product_in.description,
            website_url=product_in.website_url,
            target_market=product_in.target_market,
            pricing_model=product_in.pricing_model,
            value_propositions=json.dumps(analysis.core_value_props),
            icp_summary=analysis.icp_summary,
            target_roles=json.dumps(analysis.target_roles),
            knowledge_base=product_in.knowledge_base,
            image_features=product_in.image_features,
            telegram_handle=product_in.telegram_handle,
            telegram_bot_token=product_in.telegram_bot_token,
            is_active=True
        )
        db.add(db_product)
        db.commit()
        db.refresh(db_product)

        self.log_activity(
            db,
            role="StrategyAgent",
            action=f"Product DNA & ICP Established for '{product_in.name}'",
            details=f"Targeting: {', '.join(analysis.target_roles[:3])} in {', '.join(analysis.target_industries[:3])}",
            level="SUCCESS"
        )

        return db_product

    async def execute_prospecting_cycle(self, db: Session, product_id: int, batch_size: int = 5) -> List[Lead]:
        """
        Step 2: Autonomous Prospecting
        Runs ProspectorAgent to discover matching leads.
        """
        product = db.query(Product).filter(Product.id == product_id).first()
        if not product:
            return []

        target_roles = json.loads(product.target_roles) if product.target_roles else ["Founder", "VP of Sales"]

        self.log_activity(
            db,
            role="ProspectorAgent",
            action=f"Scanning target market for '{product.name}' prospects",
            details=f"Executing search queries across verified target accounts...",
            level="INFO"
        )

        batch_result = await self.prospector_agent.find_prospects(
            product_name=product.name,
            product_description=product.description,
            icp_summary=product.icp_summary or product.description,
            target_roles=target_roles,
            batch_size=batch_size
        )

        saved_leads = []
        for p in batch_result.leads:
            lead = Lead(
                product_id=product.id,
                name=p.name,
                company=p.company,
                role=p.role,
                email=p.email,
                linkedin_url=p.linkedin_url,
                company_website=p.company_website,
                industry=p.industry,
                estimated_revenue=p.estimated_revenue,
                confidence_score=p.confidence_score,
                status=LeadStatus.DISCOVERED,
                pain_points=p.pain_points,
                personalization_hooks=p.personalization_hooks,
                is_approved=True
            )
            db.add(lead)
            db.commit()
            db.refresh(lead)
            saved_leads.append(lead)

        self.log_activity(
            db,
            role="ProspectorAgent",
            action=f"Discovered {len(saved_leads)} Qualified Prospects",
            details=f"Top prospects: {', '.join([l.name + ' (' + l.company + ')' for l in saved_leads[:3]])}",
            level="SUCCESS"
        )

        return saved_leads

    async def execute_campaign_generation(self, db: Session, lead_id: int) -> List[Campaign]:
        """
        Step 3: Hyper-Personalized Copywriting
        Runs CopywriterAgent to craft multi-channel outreach for a given lead.
        """
        lead = db.query(Lead).filter(Lead.id == lead_id).first()
        if not lead:
            return []

        product = db.query(Product).filter(Product.id == lead.product_id).first()
        if not product:
            return []

        value_props = json.loads(product.value_propositions) if product.value_propositions else [product.description]

        self.log_activity(
            db,
            role="CopywriterAgent",
            action=f"Crafting personalized outreach sequence for {lead.name} ({lead.company})",
            details=f"Applying personalization hook: '{lead.personalization_hooks[:60]}...'",
            level="INFO"
        )

        copy_result = await self.copywriter_agent.generate_outreach_sequence(
            product_name=product.name,
            product_description=product.description,
            value_propositions=value_props,
            lead_name=lead.name,
            company=lead.company,
            role=lead.role or "Decision Maker",
            pain_points=lead.pain_points or "",
            personalization_hooks=lead.personalization_hooks or "",
            phone_number=lead.phone_number or "",
            telegram_handle=lead.telegram_handle or "",
            knowledge_base=product.knowledge_base or "",
            image_features=product.image_features or ""
        )

        created_campaigns = []
        for seq_item in copy_result.sequence:
            campaign = Campaign(
                product_id=product.id,
                lead_id=lead.id,
                channel=seq_item.channel,
                subject=seq_item.subject,
                body=seq_item.body,
                sequence_step=seq_item.step_number,
                status=CampaignStatus.DRAFT
            )
            db.add(campaign)
            db.commit()
            db.refresh(campaign)
            created_campaigns.append(campaign)

        self.log_activity(
            db,
            role="CopywriterAgent",
            action=f"Generated {len(created_campaigns)}-Step Outreach Sequence for {lead.name}",
            details=f"Multi-channel sequence ready ({', '.join([c.channel.value for c in created_campaigns])}).",
            level="SUCCESS"
        )

        return created_campaigns

    async def execute_sdr_reply_handling(self, db: Session, lead_id: int, incoming_message: str) -> SdrAnalysisResult:
        """
        Step 4: Autonomous SDR & Objection Handling
        Runs SdrAgent to analyze prospect reply, score intent, and formulate counter-response.
        """
        lead = db.query(Lead).filter(Lead.id == lead_id).first()
        if not lead:
            raise ValueError("Lead not found")

        product = db.query(Product).filter(Product.id == lead.product_id).first()
        product_name = product.name if product else "Our Solution"

        self.log_activity(
            db,
            role="SdrAgent",
            action=f"Analyzing incoming reply from {lead.name} ({lead.company})",
            details=f"Message: \"{incoming_message[:80]}...\"",
            level="INFO"
        )

        analysis = await self.sdr_agent.analyze_and_respond(
            product_name=product_name,
            lead_name=lead.name,
            lead_company=lead.company,
            incoming_message=incoming_message,
            knowledge_base=product.knowledge_base if product else None,
            product_description=product.description if product else None
        )

        # Record interaction
        interaction = Interaction(
            lead_id=lead.id,
            sender="LEAD",
            message=incoming_message,
            sentiment=analysis.sentiment,
            intent_score=analysis.intent_score,
            objection_type=analysis.objection_type,
            agent_response=analysis.suggested_reply
        )
        db.add(interaction)

        # Update lead pipeline status based on intent
        if analysis.intent_score >= 75:
            lead.status = LeadStatus.QUALIFIED
        elif analysis.intent_score >= 45:
            lead.status = LeadStatus.ENGAGED
        elif analysis.intent_score < 25:
            lead.status = LeadStatus.LOST
        
        db.commit()
        db.refresh(lead)

        self.log_activity(
            db,
            role="SdrAgent",
            action=f"Handled reply from {lead.name}: Sentiment {analysis.sentiment} (Score: {analysis.intent_score}/100)",
            details=f"Action: {analysis.recommended_action}. Pipeline status updated to {lead.status.value}.",
            level="SUCCESS"
        )

        return analysis

orchestrator = AgentOrchestrator()
