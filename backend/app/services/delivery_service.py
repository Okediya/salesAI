import os
import re
import urllib.parse
import smtplib
import logging
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from typing import Dict, Any, Optional
from datetime import datetime

from backend.app.core.config import settings

logger = logging.getLogger(__name__)

class DeliveryService:
    def __init__(self):
        pass

    @property
    def smtp_host(self) -> str:
        return settings.SMTP_HOST or os.getenv("SMTP_HOST", "")

    @property
    def smtp_port(self) -> int:
        return settings.SMTP_PORT or int(os.getenv("SMTP_PORT", "587"))

    @property
    def smtp_user(self) -> str:
        return settings.SMTP_USER or os.getenv("SMTP_USER", "")

    @property
    def smtp_password(self) -> str:
        return settings.SMTP_PASSWORD or os.getenv("SMTP_PASSWORD", "")

    @property
    def smtp_from(self) -> str:
        return settings.SMTP_FROM_EMAIL or os.getenv("SMTP_FROM_EMAIL", self.smtp_user or "salesai@autonomous-agent.ai")

    @property
    def twilio_sid(self) -> str:
        return settings.TWILIO_ACCOUNT_SID or os.getenv("TWILIO_ACCOUNT_SID", "")

    @property
    def twilio_token(self) -> str:
        return settings.TWILIO_AUTH_TOKEN or os.getenv("TWILIO_AUTH_TOKEN", "")

    @property
    def twilio_from(self) -> str:
        return settings.TWILIO_WHATSAPP_FROM or os.getenv("TWILIO_WHATSAPP_FROM", "whatsapp:+14155238886")

    def clean_phone_number(self, phone: str) -> str:
        """Sanitizes phone number for international WhatsApp format."""
        if not phone:
            return ""
        # Remove all whitespace, dashes, parentheses
        cleaned = re.sub(r"[^\d+]", "", phone.strip())
        # If starts with 0 (local e.g. Nigeria 080..., UK 07...), strip leading 0 if preceded by country code or notify
        if cleaned.startswith("+"):
            return cleaned.replace("+", "")
        return cleaned

    def generate_whatsapp_link(self, phone_number: str, message: str) -> str:
        """Generates a 1-click WhatsApp deep link with pre-filled message."""
        clean_phone = self.clean_phone_number(phone_number)
        encoded_message = urllib.parse.quote(message)
        if clean_phone:
            return f"https://api.whatsapp.com/send?phone={clean_phone}&text={encoded_message}"
        return f"https://api.whatsapp.com/send?text={encoded_message}"

    async def dispatch_whatsapp(self, phone_number: str, message: str, lead_name: str) -> Dict[str, Any]:
        """Dispatches WhatsApp outreach via Twilio API if configured, or provides direct 1-click WhatsApp link."""
        clean_phone = self.clean_phone_number(phone_number)
        direct_link = self.generate_whatsapp_link(phone_number, message)

        if self.twilio_sid and self.twilio_token and clean_phone:
            try:
                import httpx
                to_number = f"whatsapp:+{clean_phone}" if not clean_phone.startswith("+") else f"whatsapp:{clean_phone}"
                async with httpx.AsyncClient() as client:
                    resp = await client.post(
                        f"https://api.twilio.com/2010-04-01/Accounts/{self.twilio_sid}/Messages.json",
                        auth=(self.twilio_sid, self.twilio_token),
                        data={
                            "From": self.twilio_from,
                            "To": to_number,
                            "Body": message
                        }
                    )
                    if resp.status_code in (200, 201):
                        logger.info(f"WhatsApp message dispatched via Twilio to {to_number}")
                        return {
                            "success": True,
                            "channel": "WHATSAPP",
                            "recipient": phone_number,
                            "message": f"WhatsApp message successfully dispatched to {phone_number} via Twilio API.",
                            "action_url": direct_link
                        }
            except Exception as e:
                logger.warning(f"Twilio WhatsApp dispatch failed: {e}. Falling back to 1-click URL.")

        return {
            "success": True,
            "channel": "WHATSAPP",
            "recipient": phone_number or "WhatsApp",
            "message": f"WhatsApp outreach ready! Click the link below to open WhatsApp with the personalized message pre-filled for {lead_name}.",
            "action_url": direct_link
        }

    async def dispatch_email(self, to_email: str, subject: str, body: str, lead_name: str) -> Dict[str, Any]:
        """Sends a live email via SMTP if configured, or provides instant simulated preview."""
        if not to_email:
            return {
                "success": False,
                "channel": "EMAIL",
                "recipient": "None",
                "message": "No email address found for this lead.",
                "action_url": None
            }

        # If SMTP is configured, attempt live dispatch
        if self.smtp_host and self.smtp_user and self.smtp_password:
            try:
                msg = MIMEMultipart("alternative")
                msg["Subject"] = subject or "Quick question regarding your growth"
                msg["From"] = self.smtp_from
                msg["To"] = to_email

                # Plain text version
                text_part = MIMEText(body, "plain")
                msg.attach(text_part)

                # HTML formatted version
                html_content = f"""
                <div style="font-family: Arial, sans-serif; font-size: 14px; line-height: 1.6; color: #222;">
                    {body.replace(chr(10), '<br>')}
                </div>
                """
                html_part = MIMEText(html_content, "html")
                msg.attach(html_part)

                server = smtplib.SMTP(self.smtp_host, self.smtp_port, timeout=10)
                server.starttls()
                server.login(self.smtp_user, self.smtp_password)
                server.sendmail(self.smtp_from, [to_email], msg.as_string())
                server.quit()

                logger.info(f"Live cold email dispatched to {to_email} via {self.smtp_host}")
                return {
                    "success": True,
                    "channel": "EMAIL",
                    "recipient": to_email,
                    "message": f"Live cold email successfully sent to {to_email} via SMTP ({self.smtp_host})!",
                    "action_url": f"mailto:{to_email}?subject={urllib.parse.quote(subject or '')}"
                }
            except Exception as e:
                logger.error(f"SMTP error sending email to {to_email}: {e}")
                return {
                    "success": False,
                    "channel": "EMAIL",
                    "recipient": to_email,
                    "message": f"SMTP sending error: {str(e)}. (Check SMTP credentials in .env)",
                    "action_url": f"mailto:{to_email}?subject={urllib.parse.quote(subject or '')}&body={urllib.parse.quote(body)}"
                }

        # If SMTP is not yet configured in .env, generate a mailto direct link + preview
        mailto_link = f"mailto:{to_email}?subject={urllib.parse.quote(subject or '')}&body={urllib.parse.quote(body)}"
        return {
            "success": True,
            "channel": "EMAIL",
            "recipient": to_email,
            "message": f"Email prepared for {to_email}! To send directly through your mail client, click the link below or add SMTP settings in backend/.env for autonomous automated dispatch.",
            "action_url": mailto_link
        }

delivery_service = DeliveryService()
