import os
from pathlib import Path
from pydantic_settings import BaseSettings
from typing import Optional

# Resolve path to the .env file in the backend/ directory
_ENV_FILE = Path(__file__).resolve().parent.parent.parent / ".env"

class Settings(BaseSettings):
    APP_NAME: str = "SalesAI"
    ENVIRONMENT: str = "development"
    HOST: str = "0.0.0.0"
    PORT: int = 8000
    
    # Gemini API Configuration
    GEMINI_API_KEY: Optional[str] = None
    GEMINI_MODEL: str = "gemini-2.5-flash"
    GEMINI_REASONING_MODEL: str = "gemini-1.5-pro"
    
    # Database
    DATABASE_URL: str = "sqlite:///./salesai.db"
    
    # TaskMaster 24/7 Autonomous Settings
    DEFAULT_AUTONOMY_MODE: str = "AUTOPILOT"  # AUTOPILOT or COPILOT
    AUTONOMOUS_CYCLE_INTERVAL_SECONDS: int = 30
    PROSPECT_BATCH_SIZE: int = 5
    CONFIDENCE_THRESHOLD: float = 0.75
    ENABLE_GROUNDING: bool = True

    # Email (SMTP) Configuration
    SMTP_HOST: str = ""
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM_EMAIL: str = ""

    # Twilio / WhatsApp Configuration
    TWILIO_ACCOUNT_SID: str = ""
    TWILIO_AUTH_TOKEN: str = ""
    TWILIO_WHATSAPP_FROM: str = "whatsapp:+14155238886"

    class Config:
        env_file = str(_ENV_FILE)
        extra = "ignore"

settings = Settings()
