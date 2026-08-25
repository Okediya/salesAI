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

# List of common public email domains to ignore when guessing company name
PUBLIC_EMAIL_DOMAINS = {
    "gmail", "yahoo", "outlook", "hotmail", "icloud", "proton", "protonmail", "mail", "zoho", "aol"
}

class ConversationalAgent:
    """
    Intelligent, multi-turn conversational AI sales partner.
    Understands context, remembers chat history, checks live database state,
    and configures outreach channels automatically without rigid canned responses.
    """

    async def handle_user_message(
        self,
        db: Session,
        message: str,
        history: Optional[List[Dict[str, Any]]] = None
    ) -> Dict[str, Any]:
        user_text = message.strip()
        lower_msg = user_text.lower()

        active_product = db.query(Product).filter(Product.is_active == True).first()
        if not active_product:
            active_product = db.query(Product).first()

        # Clean up any bad auto-named product like "Gmail"
        if active_product and active_product.name.lower() in PUBLIC_EMAIL_DOMAINS:
            active_product.name = "My Startup"
            db.commit()

        # Extract entities from current user message
        extracted_info = self._extract_entities(user_text)

        action_type = "CONVERSATION"
        action_data = {}
        immediate_action_note = ""

        # 1. Check if user provided a Telegram Bot Token
        if extracted_info.get("telegram_bot_token"):
            token = extracted_info["telegram_bot_token"]
            bot_info = await self._verify_telegram_bot_token(token)
            if bot_info.get("valid"):
                bot_username = bot_info.get("username", "")
                bot_title = bot_info.get("first_name", "My Company")
                if not active_product:
                    active_product = Product(
                        name=bot_title,
                        tagline=f"Outbound engine via @{bot_username}",
                        description=f"Telegram bot @{bot_username} configured for autonomous outreach.",
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
                immediate_action_note = f"Telegram Bot @{bot_username} was just successfully verified and connected."

        # 2. Check if user shared website URL
        elif extracted_info.get("website_url"):
            website = extracted_info["website_url"]
            if not active_product:
                from urllib.parse import urlparse
                parsed = urlparse(website)
                comp_name = parsed.hostname.replace("www.", "").split(".")[0].capitalize() if parsed.hostname else "My Company"
                active_product = Product(
                    name=comp_name,
                    tagline=f"{comp_name} Sales Engine",
                    description=f"Website: {website}",
                    website_url=website,
                    target_market="B2B decision makers and target accounts",
                    pricing_model="Custom Tier",
                    value_propositions="Automated customer engagement and relationship-first outbound pipeline.",
                    is_active=True
                )
                db.add(active_product)
                db.commit()
                db.refresh(active_product)
                action_type = "PRODUCT_CREATED"
                action_data = {"name": comp_name, "url": website}
            else:
                active_product.website_url = website
                db.commit()

            # Scrape website in background
            try:
                scrape_res = await knowledge_extractor.scrape_website(website)
                if scrape_res.get("success"):
                    active_product.knowledge_base = scrape_res.get("summary", "")
                    db.commit()
                    immediate_action_note = f"Synced website knowledge from {website}."
            except Exception as ex:
                logger.warning(f"Auto-scrape failed: {ex}")

        # 3. Check if user provided contact info without existing product
        elif not active_product and (extracted_info.get("emails") or extracted_info.get("phone_numbers")):
            email = extracted_info["emails"][0] if extracted_info.get("emails") else ""
            phone = extracted_info["phone_numbers"][0] if extracted_info.get("phone_numbers") else ""
            comp_name = "My Startup"
            if email:
                domain_part = email.split("@")[1].split(".")[0].lower()
                if domain_part not in PUBLIC_EMAIL_DOMAINS:
                    comp_name = domain_part.capitalize()

            active_product = Product(
                name=comp_name,
                tagline=f"{comp_name} Outreach",
                description=f"Contact: {email or phone}",
                target_market="B2B decision makers",
                pricing_model="Custom Tier",
                value_propositions="Automated customer engagement",
                is_active=True
            )
            db.add(active_product)
            db.commit()
            db.refresh(active_product)
            action_type = "PRODUCT_CREATED"
            action_data = {"name": comp_name}
            immediate_action_note = f"Saved your contact info ({email or phone}) and created company profile '{comp_name}'."

        # 4. Check if user asked to find leads/customers
        if "find" in lower_msg and ("customer" in lower_msg or "lead" in lower_msg or "prospect" in lower_msg or "friend" in lower_msg):
            if active_product:
                discovered = await orchestrator.execute_prospecting_cycle(db, active_product.id, batch_size=3)
                action_type = "PROSPECTS_DISCOVERED"
                action_data = {"count": len(discovered), "leads": [l.name for l in discovered]}
                immediate_action_note = f"Found {len(discovered)} qualified decision makers: {', '.join([l.name for l in discovered])}."

        # 5. Check if user pasted customer list / handles
        elif extracted_info.get("telegram_handles") or (extracted_info.get("emails") and active_product):
            imported_count = await self._auto_import_leads(db, extracted_info, active_product)
            if imported_count > 0:
                action_type = "LEADS_IMPORTED"
                action_data = {"count": imported_count}
                immediate_action_note = f"Imported {imported_count} contacts into the active pipeline."

        # Build live database state context
        lead_count = db.query(Lead).count() if active_product else 0
        has_telegram_bot = bool(active_product and active_product.telegram_bot_token)
        telegram_handle = active_product.telegram_handle if active_product else None
        website_url = active_product.website_url if active_product else None

        db_context = f"""
LIVE SYSTEM STATE:
- Active Company: {active_product.name if active_product else 'Not configured yet'}
- Website: {website_url or 'None'}
- Telegram Bot: {'Connected (@' + telegram_handle + ')' if has_telegram_bot else 'Not connected yet'}
- Total Leads in Pipeline: {lead_count}
- Immediate Event Just Handled: {immediate_action_note or 'None'}
"""

        # Format recent chat history
        history_formatted = ""
        if history and isinstance(history, list):
            recent_turns = history[-6:]
            for turn in recent_turns:
                role = "User" if turn.get("sender") == "user" or turn.get("role") == "user" else "SalesAI"
                text = turn.get("text") or turn.get("parts") or ""
                if text:
                    history_formatted += f"{role}: {text}\n"

        prompt = f"""
You are SalesAI, a dedicated, warm, and highly intelligent human-like sales partner and co-founder.
You talk naturally like an experienced growth partner. You have full context of our conversation and live setup.

{db_context}

RECENT CONVERSATION HISTORY:
{history_formatted}

CURRENT USER MESSAGE:
{user_text}

INSTRUCTIONS:
1. Respond directly and conversationally to what the user just asked in context of the conversation.
2. If the user asks about Telegram ("did you link it?", "how to link telegram", etc.), give a specific, accurate answer based on the LIVE SYSTEM STATE above:
   - If Telegram is connected: Confirm warmly that @{telegram_handle} is linked and ready.
   - If not connected: Explain that they can message @BotFather on Telegram, type /newbot, and paste the HTTP API token right here in chat.
3. If the user says hello or asks how you are, reply warmly, naturally, and ask how you can help with their sales today.
4. If the user shares their website, product description, or target audience, acknowledge what they do with genuine interest.
5. NEVER repeat rigid canned disclaimers or repetitive robotic templates.
6. Strictly DO NOT use any emojis anywhere in your response.
"""

        bot_reply = await self._generate_ai_response(prompt)

        # Fallback intelligent rule-based dynamic generator if all AI models fail
        if not bot_reply:
            bot_reply = self._generate_contextual_fallback(
                user_text,
                lower_msg,
                active_product,
                has_telegram_bot,
                telegram_handle,
                immediate_action_note
            )

        bot_reply = self._strip_emojis(bot_reply)

        orchestrator.log_activity(
            db,
            role="SalesAI Partner",
            action=f"Chat interaction: {user_text[:50]}",
            details=bot_reply[:100],
            level="INFO"
        )

        return {
            "reply": bot_reply,
            "action_type": action_type,
            "action_data": action_data,
            "extracted_info": extracted_info
        }

    async def _generate_ai_response(self, prompt: str) -> str:
        """Tries multiple Gemini models in sequence with graceful fallback."""
        models_to_try = ["gemini-2.5-flash", "gemini-2.0-flash", "gemini-1.5-flash"]
        
        # 1. Try google-genai modern SDK
        if gemini_client._genai_client:
            for model_name in models_to_try:
                try:
                    resp = gemini_client._genai_client.models.generate_content(
                        model=model_name,
                        contents=prompt,
                    )
                    if resp and resp.text:
                        return resp.text.strip()
                except Exception as e:
                    logger.warning(f"GenAI SDK attempt with {model_name} failed: {e}")

        # 2. Try legacy google.generativeai SDK
        if gemini_client._legacy_genai:
            for model_name in ["gemini-1.5-flash", "gemini-1.5-pro"]:
                try:
                    model = gemini_client._legacy_genai.GenerativeModel(model_name)
                    resp = model.generate_content(prompt)
                    if resp and resp.text:
                        return resp.text.strip()
                except Exception as ex:
                    logger.warning(f"Legacy genai attempt with {model_name} failed: {ex}")

        return ""

    def _generate_contextual_fallback(
        self,
        text: str,
        lower: str,
        product: Optional[Product],
        has_telegram: bool,
        telegram_handle: Optional[str],
        immediate_action_note: str
    ) -> str:
        """Intelligent contextual fallback when API quota is unavailable."""
        if immediate_action_note:
            return f"Done. {immediate_action_note} Let me know what you would like to do next—we can search for leads, draft outreach messages, or check on our pipeline."

        # Greetings
        if any(w in lower for w in ["hello", "hi", "hey", "good morning", "good afternoon", "how are you"]):
            if product:
                tg_status = f"Our Telegram bot @{telegram_handle} is active." if has_telegram else "We haven't connected a Telegram bot yet."
                return f"Hello! Great to be working with you on {product.name}. {tg_status} What would you like to focus on right now? We can find new decision makers, draft an outreach sequence, or import customer contacts."
            return "Hello! I am SalesAI, your growth and outbound partner. What is your company website or product name so we can get our sales engine rolling?"

        # Telegram questions
        if "telegram" in lower or "bot" in lower:
            if "link" in lower or "connected" in lower or "status" in lower or "did you" in lower or "have you" in lower:
                if has_telegram:
                    return f"Yes! Your Telegram bot @{telegram_handle} is linked and ready. You can command me to reach out to leads or paste Telegram usernames for automated follow-ups."
                return "Telegram is not connected yet. To link it, message @BotFather on Telegram with /newbot, copy the HTTP API Token, and paste it right here in our chat."
            return "To connect your Telegram bot, message @BotFather on Telegram, create a bot with /newbot, and paste the HTTP API Token here. I will link it automatically."

        # Finding customers
        if "find" in lower or "prospect" in lower or "customer" in lower or "lead" in lower:
            if product:
                return f"I am scanning for verified decision makers matching {product.name}'s ICP. You can review all discovered prospects in the Pipeline Kanban tab."
            return "Please share your website or product description first so I know what target customer profiles to look for."

        # Ad or copywriting
        if "ad" in lower or "copy" in lower or "pitch" in lower or "message" in lower:
            p_name = product.name if product else "our solution"
            return f"Here is a warm, relationship-first outreach message for {p_name}:\n\nHi [Name],\n\nHope your week is going well! Saw your recent work and wanted to say hello. We help teams automate customer acquisition without the manual overhead. Would love to share how teams in your space are scaling pipeline if you're open to a brief chat."

        # Default conversational response
        if product:
            return f"I am ready. We are set up for {product.name}. You can paste customer handles or emails, ask me to find new leads, or command an outreach campaign."
        return "I am ready to help you sell. Share your company website, email, phone number, or Telegram bot token to get started."

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

    def _strip_emojis(self, text: str) -> str:
        emoji_pattern = re.compile(
            r"[\U00010000-\U0010ffff]|[\u2600-\u27ff]|[\u2300-\u23ff]|[\u2b50]|[\u3030]",
            flags=re.UNICODE
        )
        return emoji_pattern.sub("", text)

conversational_agent = ConversationalAgent()
