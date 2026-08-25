import os
import re
import json
import httpx
import logging
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session

from backend.app.core.gemini_client import gemini_client
from backend.app.models.db_models import Product, Lead, Campaign, ActivityLog, LeadStatus, ChannelType, CampaignStatus
from backend.app.models.schemas import ProductCreate, LeadCreate
from backend.app.agents.orchestrator import orchestrator
from backend.app.services.knowledge_extractor import knowledge_extractor
from backend.app.services.delivery_service import delivery_service
from backend.app.engine.taskmaster_loop import taskmaster_engine

logger = logging.getLogger(__name__)

class ConversationalAgent:
    """
    Primary conversational sales partner.
    Interacts naturally like a warm, supportive colleague.
    Configures itself automatically from emails, phone numbers, website links, or Telegram tokens.
    """

    async def handle_user_message(
        self,
        db: Session,
        message: str,
        history: Optional[List[Dict[str, str]]] = None
    ) -> Dict[str, Any]:
        user_text = message.strip()
        active_product = db.query(Product).filter(Product.is_active == True).first()
        if not active_product:
            active_product = db.query(Product).first()

        # Extract entities from user message
        extracted_info = self._extract_entities(user_text)

        # Context for AI partner
        product_context = "No company configured yet."
        if active_product:
            product_context = (
                f"Company: {active_product.name}\n"
                f"Tagline: {active_product.tagline or 'N/A'}\n"
                f"Website: {active_product.website_url or 'N/A'}\n"
                f"Telegram Bot: {active_product.telegram_handle or 'Not connected'}\n"
                f"Target ICP: {active_product.icp_summary or 'N/A'}\n"
                f"Knowledge Base: {(active_product.knowledge_base or '')[:300]}"
            )

        prompt = f"""
You are SalesAI, a dedicated, warm, and highly capable sales and marketing partner.
You speak with genuine human warmth, authenticity, and empathy like a sharp co-founder or head of growth.
Do NOT use emojis anywhere in your response. Keep your tone natural, friendly, and helpful.

CURRENT COMPANY CONTEXT:
{product_context}

USER MESSAGE:
{user_text}

EXTRACTED ENTITIES FROM USER INPUT:
{json.dumps(extracted_info)}

INSTRUCTIONS:
1. If the user provides an email, phone number, website, or Telegram token, congratulate and thank them warmly, confirming that their company identity and outreach channels are now automatically configured.
2. If the user asks about creating a Telegram bot, explain that you can connect it instantly—they just need to open Telegram @BotFather, type /newbot, and paste the HTTP API Token here.
3. If the user asks to find customers or reach out to people, explain that you will discover verified decision makers and craft warm, friendly relationship-building messages to befriend them and share value.
4. If the user asks to write an ad or check in on leads, generate friendly, authentic copy focused on solving real problems without aggressive sales hype.
5. Speak as their partner ("I've set this up for us", "Here is what I suggest we do next").
"""

        bot_reply = ""
        action_type = "CONVERSATION"
        action_data = {}

        # Gemini generation
        if gemini_client._genai_client:
            try:
                resp = gemini_client._genai_client.models.generate_content(
                    model="gemini-2.5-flash",
                    contents=prompt,
                )
                if resp and resp.text:
                    bot_reply = resp.text.strip()
            except Exception as e:
                logger.warning(f"GenAI chat error: {e}")

        if not bot_reply and gemini_client._legacy_genai:
            try:
                model = gemini_client._legacy_genai.GenerativeModel("gemini-1.5-flash")
                resp = model.generate_content(prompt)
                if resp and resp.text:
                    bot_reply = resp.text.strip()
            except Exception as e:
                logger.warning(f"Legacy genai chat error: {e}")

        if not bot_reply:
            bot_reply = self._generate_rule_based_response(user_text, extracted_info, active_product)

        # Strip emojis to maintain minimalist monochrome theme
        bot_reply = self._strip_emojis(bot_reply)

        lower_msg = user_text.lower()

        # Handle Telegram Bot Token verification & self-configuration
        if extracted_info.get("telegram_bot_token"):
            token = extracted_info["telegram_bot_token"]
            bot_info = await self._verify_telegram_bot_token(token)
            if bot_info.get("valid"):
                bot_username = bot_info.get("username", "")
                if not active_product:
                    active_product = Product(
                        name=bot_info.get("first_name", "My Company"),
                        tagline=f"Outbound engine via @{bot_username}",
                        description=f"Telegram bot @{bot_username} configured for autonomous customer outreach.",
                        telegram_handle=bot_username,
                        telegram_bot_token=token,
                        is_active=True
                    )
                    db.add(active_product)
                else:
                    active_product.telegram_bot_token = token
                    active_product.telegram_handle = bot_username
                db.commit()
                db.refresh(active_product)

                action_type = "TELEGRAM_BOT_CONNECTED"
                action_data = {"bot_username": bot_username}
                bot_reply += f"\n\nTelegram Bot Connected: Verified @{bot_username}. I am now able to autonomously send messages and check-ins directly through your Telegram bot."

        # Auto-create product if none exists and user provides details
        elif not active_product and (extracted_info.get("website_url") or extracted_info.get("emails") or extracted_info.get("phone_numbers")):
            try:
                website = extracted_info.get("website_url") or ""
                email = extracted_info["emails"][0] if extracted_info.get("emails") else ""
                phone = extracted_info["phone_numbers"][0] if extracted_info.get("phone_numbers") else ""
                company_name = "My Company"
                if website:
                    from urllib.parse import urlparse
                    parsed = urlparse(website)
                    company_name = parsed.hostname.replace("www.", "").split(".")[0].capitalize() if parsed.hostname else "My Company"
                elif email:
                    company_name = email.split("@")[1].split(".")[0].capitalize()

                new_product = Product(
                    name=company_name,
                    tagline=f"{company_name} - Autonomous Sales Engine",
                    description=f"Company onboarded automatically via chat. Website: {website}. Contact: {email or phone}.",
                    website_url=website or None,
                    target_market="B2B decision makers and target accounts",
                    pricing_model="Custom Tier",
                    value_propositions="Automated customer engagement and relationship-first outbound pipeline.",
                    is_active=True,
                )
                db.add(new_product)
                db.commit()
                db.refresh(new_product)
                active_product = new_product
                action_type = "PRODUCT_CREATED"
                action_data = {"product_id": new_product.id, "name": new_product.name}

                # Auto-scrape website in background
                if website:
                    try:
                        scrape_res = await knowledge_extractor.scrape_website(website)
                        if scrape_res.get("success"):
                            active_product.knowledge_base = scrape_res.get("summary", "")
                            db.commit()
                    except Exception:
                        pass

                bot_reply += f"\n\nI have configured our company profile for \"{company_name}\" and set your contact channels. What kind of customers should we befriend and reach out to?"
            except Exception as ex:
                logger.warning(f"Auto-create product failed: {ex}")

        # Update existing active product with new contact info
        elif active_product and (extracted_info.get("website_url") or extracted_info.get("emails")):
            if extracted_info.get("website_url") and not active_product.website_url:
                active_product.website_url = extracted_info["website_url"]
                db.commit()

        # Handle prospect discovery command
        if "find" in lower_msg and ("customer" in lower_msg or "lead" in lower_msg or "prospect" in lower_msg or "friend" in lower_msg):
            if active_product:
                discovered = await orchestrator.execute_prospecting_cycle(db, active_product.id, batch_size=3)
                action_type = "PROSPECTS_DISCOVERED"
                action_data = {"count": len(discovered), "leads": [l.name for l in discovered]}
                bot_reply += f"\n\nFound {len(discovered)} qualified decision makers to reach out to. You can review them in the Pipeline tab."
            else:
                bot_reply += "\n\nPlease share your company website or contact details first so I can tailor the prospect search."

        # Handle batch lead imports from chat
        elif extracted_info.get("telegram_handles") or (extracted_info.get("emails") and active_product):
            imported_count = await self._auto_import_leads(db, extracted_info, active_product)
            if imported_count > 0:
                action_type = "LEADS_IMPORTED"
                action_data = {"count": imported_count}

        orchestrator.log_activity(
            db,
            role="SalesAI Partner",
            action=f"Chat message: {user_text[:50]}",
            details=bot_reply[:100],
            level="INFO"
        )

        return {
            "reply": bot_reply,
            "action_type": action_type,
            "action_data": action_data,
            "extracted_info": extracted_info
        }

    async def _verify_telegram_bot_token(self, token: str) -> Dict[str, Any]:
        """Tests the Telegram Bot API getMe endpoint to verify token validity."""
        url = f"https://api.telegram.org/bot{token}/getMe"
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                res = await client.get(url)
                if res.status_code == 200:
                    data = res.json()
                    if data.get("ok"):
                        result = data.get("result", {})
                        return {
                            "valid": True,
                            "username": result.get("username", ""),
                            "first_name": result.get("first_name", ""),
                        }
        except Exception as e:
            logger.warning(f"Telegram token validation error: {e}")
        return {"valid": False}

    def _extract_entities(self, text: str) -> Dict[str, Any]:
        # Telegram Bot Token format: 123456789:ABCDefGhIJKlmNoPQRsTUVwxyZ_1234567
        bot_tokens = re.findall(r"\b([0-9]{8,11}:[a-zA-Z0-9_-]{34,38})\b", text)
        emails = re.findall(r"[\w\.-]+@[\w\.-]+\.\w+", text)
        phones = re.findall(r"[\+\(]?[0-9][0-9 \-\(\)]{7,}[0-9]", text)
        telegram_handles = re.findall(r"@([a-zA-Z0-9_]{3,32})", text)
        urls = re.findall(r"https?://[^\s]+", text)

        return {
            "telegram_bot_token": bot_tokens[0] if bot_tokens else None,
            "emails": emails,
            "phone_numbers": [p.strip() for p in phones],
            "telegram_handles": telegram_handles,
            "website_url": urls[0] if urls else None
        }

    async def _auto_import_leads(self, db: Session, entities: Dict[str, Any], product: Optional[Product]) -> int:
        if not product:
            return 0

        count = 0
        for tg in entities.get("telegram_handles", []):
            lead = Lead(
                product_id=product.id,
                name=f"Telegram User @{tg}",
                company="Prospective Account",
                role="Decision Maker",
                telegram_handle=tg,
                status=LeadStatus.DISCOVERED,
                confidence_score=0.92,
                pain_points="Direct contact imported for relationship-building and friendly check-ins",
                is_approved=True
            )
            db.add(lead)
            count += 1

        for em in entities.get("emails", []):
            lead = Lead(
                product_id=product.id,
                name=em.split("@")[0].capitalize(),
                company=em.split("@")[1].split(".")[0].capitalize(),
                role="Contact",
                email=em,
                status=LeadStatus.DISCOVERED,
                confidence_score=0.90,
                pain_points="Direct subscriber for friendly updates and product news",
                is_approved=True
            )
            db.add(lead)
            count += 1

        if count > 0:
            db.commit()
            await taskmaster_engine.broadcast_event("BATCH_LEADS_IMPORTED", {"count": count})
        return count

    def _generate_rule_based_response(self, text: str, entities: Dict[str, Any], product: Optional[Product]) -> str:
        lower = text.lower()
        if not product:
            if entities.get("website_url") or entities.get("emails"):
                return "Got it. I have configured our company details from what you shared. Tell me what problem your product solves, and I will begin finding people who need it."
            return "Hello. I am SalesAI, your 24/7 sales and marketing partner. Give me your email, phone number, company website, or Telegram bot token, and I will set everything up and start finding customers."

        if "telegram" in lower and ("bot" in lower or "create" in lower or "setup" in lower):
            return "To connect your Telegram bot, open Telegram and message @BotFather with /newbot. Once you get the HTTP API Token, simply paste it right here in chat and I will link it automatically."

        if "find" in lower or "prospect" in lower or "customer" in lower:
            return f"Initiating customer discovery for {product.name}. I am identifying verified decision makers matching your ICP."

        if "ad" in lower or "copy" in lower or "pitch" in lower:
            return f"Here is a warm, relationship-first outreach message for {product.name}:\n\nHi [Name],\n\nHope your week is off to a great start! Saw what you're working on and wanted to reach out. We help teams streamline customer acquisition without the headache of manual prospecting. Would love to hear how you're approaching growth right now if you're open to a brief chat."

        return f"Understood. I am keeping track of our pipeline for {product.name}. You can share customer contacts, ask me to draft ads, or command an outreach run anytime."

    def _strip_emojis(self, text: str) -> str:
        emoji_pattern = re.compile(
            r"[\U00010000-\U0010ffff]|[\u2600-\u27ff]|[\u2300-\u23ff]|[\u2b50]|[\u3030]",
            flags=re.UNICODE
        )
        return emoji_pattern.sub("", text)

conversational_agent = ConversationalAgent()
