import enum
import datetime
from sqlalchemy import Column, Integer, String, Text, Float, Boolean, DateTime, ForeignKey, Enum
from sqlalchemy.orm import relationship
from backend.app.core.database import Base

class AutonomyMode(str, enum.Enum):
    AUTOPILOT = "AUTOPILOT"
    COPILOT = "COPILOT"

class LeadStatus(str, enum.Enum):
    DISCOVERED = "DISCOVERED"
    CONTACTED = "CONTACTED"
    ENGAGED = "ENGAGED"
    QUALIFIED = "QUALIFIED"
    WON = "WON"
    LOST = "LOST"

class ChannelType(str, enum.Enum):
    EMAIL = "EMAIL"
    LINKEDIN = "LINKEDIN"
    TWITTER = "TWITTER"
    WHATSAPP = "WHATSAPP"
    TELEGRAM = "TELEGRAM"

class CampaignStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    SCHEDULED = "SCHEDULED"
    SENT = "SENT"
    REPLIED = "REPLIED"

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    tagline = Column(String(500), nullable=True)
    description = Column(Text, nullable=False)
    website_url = Column(String(500), nullable=True)
    target_market = Column(Text, nullable=True)
    pricing_model = Column(String(255), nullable=True)
    value_propositions = Column(Text, nullable=True)  # JSON or newline list
    icp_summary = Column(Text, nullable=True)          # Extracted ICP by StrategyAgent
    target_roles = Column(Text, nullable=True)         # Target decision maker titles
    knowledge_base = Column(Text, nullable=True)       # Scraped and extracted website knowledge
    image_features = Column(Text, nullable=True)       # Gemini Vision extracted visual UI/product features
    telegram_handle = Column(String(255), nullable=True)  # Company/Bot Telegram handle
    telegram_bot_token = Column(String(255), nullable=True) # Optional Telegram Bot Token
    website_last_synced = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    leads = relationship("Lead", back_populates="product", cascade="all, delete-orphan")
    campaigns = relationship("Campaign", back_populates="product", cascade="all, delete-orphan")

class Lead(Base):
    __tablename__ = "leads"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    name = Column(String(255), nullable=False)
    company = Column(String(255), nullable=False)
    role = Column(String(255), nullable=True)
    email = Column(String(255), nullable=True)
    phone_number = Column(String(50), nullable=True)
    telegram_handle = Column(String(255), nullable=True)
    linkedin_url = Column(String(500), nullable=True)
    twitter_handle = Column(String(255), nullable=True)
    company_website = Column(String(500), nullable=True)
    industry = Column(String(255), nullable=True)
    estimated_revenue = Column(String(100), nullable=True)
    confidence_score = Column(Float, default=0.85)
    status = Column(Enum(LeadStatus), default=LeadStatus.DISCOVERED)
    pain_points = Column(Text, nullable=True)
    personalization_hooks = Column(Text, nullable=True)
    is_approved = Column(Boolean, default=True)  # For Copilot approval
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

    product = relationship("Product", back_populates="leads")
    campaigns = relationship("Campaign", back_populates="lead", cascade="all, delete-orphan")
    interactions = relationship("Interaction", back_populates="lead", cascade="all, delete-orphan")

class Campaign(Base):
    __tablename__ = "campaigns"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    lead_id = Column(Integer, ForeignKey("leads.id"), nullable=True)
    channel = Column(Enum(ChannelType), default=ChannelType.EMAIL)
    subject = Column(String(500), nullable=True)
    body = Column(Text, nullable=False)
    sequence_step = Column(Integer, default=1)
    status = Column(Enum(CampaignStatus), default=CampaignStatus.DRAFT)
    sent_at = Column(DateTime, nullable=True)
    open_rate_sim = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    product = relationship("Product", back_populates="campaigns")
    lead = relationship("Lead", back_populates="campaigns")

class Interaction(Base):
    __tablename__ = "interactions"

    id = Column(Integer, primary_key=True, index=True)
    lead_id = Column(Integer, ForeignKey("leads.id"), nullable=False)
    sender = Column(String(50), default="LEAD")  # LEAD or AGENT
    message = Column(Text, nullable=False)
    sentiment = Column(String(50), default="NEUTRAL")  # POSITIVE, SKEPTICAL, OBJECTION, NEGATIVE
    intent_score = Column(Float, default=50.0)          # 0-100 score
    objection_type = Column(String(100), nullable=True) # Price, Timing, Competitor, Feature
    agent_response = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    lead = relationship("Lead", back_populates="interactions")

class ActivityLog(Base):
    __tablename__ = "activity_logs"

    id = Column(Integer, primary_key=True, index=True)
    agent_role = Column(String(100), nullable=False) # StrategyAgent, ProspectorAgent, CopywriterAgent, SdrAgent, TaskMaster
    action = Column(String(255), nullable=False)
    details = Column(Text, nullable=True)
    level = Column(String(50), default="INFO")       # INFO, SUCCESS, WARNING, ACTION_REQUIRED
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class AgentState(Base):
    __tablename__ = "agent_state"

    id = Column(Integer, primary_key=True, index=True)
    is_running = Column(Boolean, default=True)
    autonomy_mode = Column(Enum(AutonomyMode), default=AutonomyMode.AUTOPILOT)
    cycle_interval = Column(Integer, default=30) # seconds
    cycles_completed = Column(Integer, default=0)
    last_cycle_at = Column(DateTime, nullable=True)
    current_task = Column(String(255), default="Idle")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
