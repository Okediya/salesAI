from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime
from backend.app.models.db_models import AutonomyMode, LeadStatus, ChannelType, CampaignStatus

# --- Product Schemas ---
class ProductCreate(BaseModel):
    name: str = Field(..., description="Name of the product or startup")
    tagline: Optional[str] = Field(None, description="Catchy one-line tagline")
    description: str = Field(..., description="Detailed description of what the product does and problems it solves")
    website_url: Optional[str] = Field(None, description="Product website URL")
    target_market: Optional[str] = Field(None, description="Target industry, company size, geography")
    pricing_model: Optional[str] = Field(None, description="Pricing model e.g. $49/mo, Free tier, Enterprise quote")
    value_propositions: Optional[str] = Field(None, description="Key differentiators and value props")
    telegram_handle: Optional[str] = Field(None, description="Company or sales Telegram username/handle")
    telegram_bot_token: Optional[str] = Field(None, description="Optional Telegram bot token for automated dispatch")
    knowledge_base: Optional[str] = Field(None, description="Scraped or provided company knowledge base")
    image_features: Optional[str] = Field(None, description="Gemini Vision extracted visual UI/product features")

class ProductResponse(ProductCreate):
    id: int
    icp_summary: Optional[str] = None
    target_roles: Optional[str] = None
    knowledge_base: Optional[str] = None
    image_features: Optional[str] = None
    telegram_handle: Optional[str] = None
    telegram_bot_token: Optional[str] = None
    website_last_synced: Optional[datetime] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class WebsiteSyncRequest(BaseModel):
    website_url: Optional[str] = None

class WebsiteSyncResponse(BaseModel):
    success: bool
    website_url: str
    extracted_knowledge_summary: str
    synced_at: datetime

class ImageAnalysisRequest(BaseModel):
    image_base64: str = Field(..., description="Base64 encoded image or screenshot of the product")
    image_type: Optional[str] = "image/png"
    notes: Optional[str] = None

class ImageAnalysisResponse(BaseModel):
    success: bool
    extracted_ui_features: str
    detected_capabilities: List[str] = []
    analyzed_at: datetime

# --- Structured Agent Output Schemas ---
class TargetPersona(BaseModel):
    role_title: str
    seniority: str
    core_pain_point: str
    primary_gain: str
    trigger_events: List[str] = []

class ProductStrategyAnalysis(BaseModel):
    product_dna_summary: str
    icp_summary: str
    target_industries: List[str]
    target_roles: List[str]
    core_value_props: List[str]
    personas: List[TargetPersona]
    market_hooks: List[str]

class DiscoveredProspect(BaseModel):
    name: str
    company: str
    role: str
    email: Optional[str] = None
    phone_number: Optional[str] = None
    linkedin_url: Optional[str] = None
    company_website: Optional[str] = None
    industry: Optional[str] = None
    estimated_revenue: Optional[str] = None
    confidence_score: float = Field(default=0.85, ge=0.0, le=1.0)
    pain_points: str
    personalization_hooks: str

class ProspectorBatchResult(BaseModel):
    leads: List[DiscoveredProspect]
    discovery_summary: str
    search_queries_used: List[str] = []

class OutreachSequenceItem(BaseModel):
    channel: ChannelType
    step_number: int
    subject: Optional[str] = None
    body: str
    call_to_action: str

class CampaignCopyResult(BaseModel):
    lead_name: str
    company: str
    hook_reason: str
    sequence: List[OutreachSequenceItem]

class SdrAnalysisResult(BaseModel):
    sentiment: str = Field(..., description="POSITIVE, SKEPTICAL, OBJECTION, NEGATIVE")
    intent_score: float = Field(..., description="0 to 100 purchase intent score")
    objection_type: Optional[str] = Field(None, description="Price, Timing, Competitor, Feature, Authority")
    recommended_action: str = Field(..., description="PROCEED_TO_DEMO, SEND_CASE_STUDY, OVERCOME_OBJECTION, NURTURE, DISQUALIFY")
    suggested_reply: str
    confidence: float = 0.9

# --- Lead Schemas ---
class LeadCreate(BaseModel):
    name: str = Field(..., description="Full name of the prospect/lead")
    company: str = Field(..., description="Company name")
    role: Optional[str] = Field("Founder & CEO", description="Job title / role")
    email: Optional[str] = Field(None, description="Email address")
    phone_number: Optional[str] = Field(None, description="WhatsApp or mobile phone number")
    telegram_handle: Optional[str] = Field(None, description="Telegram username (e.g. @username or username)")
    linkedin_url: Optional[str] = Field(None, description="LinkedIn profile or company page")
    pain_points: Optional[str] = Field(None, description="Specific business challenges or pain points")
    personalization_hooks: Optional[str] = Field(None, description="Context, recent milestones, or angle to hook")
    auto_generate_campaign: bool = Field(True, description="Whether to immediately trigger AI outreach copy generation")

class LeadResponse(BaseModel):
    id: int
    product_id: int
    name: str
    company: str
    role: Optional[str] = None
    email: Optional[str] = None
    phone_number: Optional[str] = None
    telegram_handle: Optional[str] = None
    linkedin_url: Optional[str] = None
    twitter_handle: Optional[str] = None
    company_website: Optional[str] = None
    industry: Optional[str] = None
    confidence_score: float
    status: LeadStatus
    pain_points: Optional[str] = None
    personalization_hooks: Optional[str] = None
    is_approved: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class LeadStatusUpdate(BaseModel):
    status: LeadStatus

class DeliveryResult(BaseModel):
    success: bool
    channel: str
    recipient: str
    message: str
    action_url: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class InboundMessageRequest(BaseModel):
    message: str = Field(..., description="Inbound text received from lead via Telegram/Email/Chat")
    channel: Optional[ChannelType] = ChannelType.TELEGRAM
    auto_dispatch_reply: bool = Field(True, description="Whether to automatically dispatch the SDR reply back to the lead")

class InboundMessageResponse(BaseModel):
    success: bool
    sentiment: str
    intent_score: float
    objection_type: Optional[str] = None
    recommended_action: str
    agent_reply: str
    dispatch_result: Optional[DeliveryResult] = None
    processed_at: datetime

# --- Campaign Schemas ---
class CampaignResponse(BaseModel):
    id: int
    product_id: int
    lead_id: Optional[int] = None
    channel: ChannelType
    subject: Optional[str] = None
    body: str
    sequence_step: int
    status: CampaignStatus
    sent_at: Optional[datetime] = None
    created_at: datetime

    class Config:
        from_attributes = True

# --- Interaction Schemas ---
class InteractionCreate(BaseModel):
    lead_id: int
    message: str

class InteractionResponse(BaseModel):
    id: int
    lead_id: int
    sender: str
    message: str
    sentiment: str
    intent_score: float
    objection_type: Optional[str] = None
    agent_response: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True

# --- Activity Log Schemas ---
class ActivityLogResponse(BaseModel):
    id: int
    agent_role: str
    action: str
    details: Optional[str] = None
    level: str
    created_at: datetime

    class Config:
        from_attributes = True

# --- Agent State & Controls ---
class AgentStateResponse(BaseModel):
    is_running: bool
    autonomy_mode: AutonomyMode
    cycle_interval: int
    cycles_completed: int
    last_cycle_at: Optional[datetime] = None
    current_task: str

class AgentControlRequest(BaseModel):
    action: str = Field(..., description="START, PAUSE, TRIGGER_CYCLE, SET_MODE")
    autonomy_mode: Optional[AutonomyMode] = None
    cycle_interval: Optional[int] = None

# --- Dashboard Stats ---
class DashboardStatsResponse(BaseModel):
    total_leads: int
    discovered_leads: int
    contacted_leads: int
    engaged_leads: int
    qualified_leads: int
    won_leads: int
    total_campaigns_sent: int
    average_intent_score: float
    agent_state: AgentStateResponse
    active_product: Optional[ProductResponse] = None
    recent_activities: List[ActivityLogResponse] = []
