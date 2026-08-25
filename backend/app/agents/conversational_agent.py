import os
import re
import json
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
    Interacts with the user via chat, gathers startup details (website, phone, email, telegram),
    discovers customers, ingests customer lists, generates ads, and runs daily follow-ups.
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

        # Check for extracted entities in user message (URLs, emails, phone numbers, telegram handles)
        extracted_info = self._extract_entities(user_text)

        # Build context for the AI partner
        product_context = "No product onboarded yet."
        if active_product:
            product_context = f"Product: {active_product.name}\nTagline: {active_product.tagline or 'N/A'}\nWebsite: {active_product.website_url or 'N/A'}\nTelegram: {active_product.telegram_handle or 'N/A'}\nTarget ICP: {active_product.icp_summary or 'N/A'}\nKnowledge Base: {(active_product.knowledge_base or '')[:300]}"

        prompt = f"""
You are SalesAI, a dedicated autonomous sales and marketing partner.
You speak like a sharp, professional human sales executive.
Do NOT use emojis anywhere in your response. Keep your tone direct, efficient, and results-focused.

CURRENT PRODUCT STATE:
{product_context}

USER MESSAGE:
{user_text}

EXTRACTED ENTITIES FROM USER INPUT:
{json.dumps(extracted_info)}

INSTRUCTIONS:
1. If the user is sharing contact info (email, phone, Telegram handle, website), acknowledge it cleanly and update the product profile or ask for next steps (like what problem they solve, target customers, or product screenshot).
2. If the user asks to find customers/leads, explain that you are initiating a prospect discovery cycle.
3. If the user provides a list of contacts/leads (e.g. @handles or emails), acknowledge that they will be ingested for continuous follow-up and updates.
4. If the user asks to write an ad, pitch, or campaign sequence, provide high-converting copy without hype or buzzwords.
5. If the user asks you to check up on customers or follow up, confirm the scheduled follow-up outreach.
6. Provide a concise, helpful response and recommend the next actionable step.
"""

        bot_reply = ""
        action_type = "CONVERSATION"
        action_data = {}

        # Use Gemini to generate conversational response
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

        # Fallback intelligent rule-based response if offline
        if not bot_reply:
            bot_reply = self._generate_rule_based_response(user_text, extracted_info, active_product)

        # Strip any accidental emojis from output to enforce pure black-and-white professional theme
        bot_reply = self._strip_emojis(bot_reply)

        # Handle automated background actions triggered by conversation
        lower_msg = user_text.lower()

        # Auto-create product from chat if none exists and user provides enough info
        if not active_product and (extracted_info.get("website_url") or extracted_info.get("emails") or extracted_info.get("phone_numbers")):
            try:
                website = extracted_info.get("website_url") or ""
                email = extracted_info["emails"][0] if extracted_info.get("emails") else ""
                phone = extracted_info["phone_numbers"][0] if extracted_info.get("phone_numbers") else ""
                # Derive a company name from domain or email domain
                company_name = "My Company"
                if website:
                    from urllib.parse import urlparse
                    parsed = urlparse(website)
                    company_name = parsed.hostname.replace("www.", "").split(".")[0].capitalize() if parsed.hostname else "My Company"
                elif email:
                    company_name = email.split("@")[1].split(".")[0].capitalize()

                new_product = Product(
                    name=company_name,
                    tagline=f"{company_name} - Sales Outreach",
                    description=f"Product onboarded via chat. Website: {website}. Contact: {email or phone}.",
                    website_url=website or None,
                    target_market="B2B decision makers and potential customers",
                    pricing_model="Contact for pricing",
                    value_propositions="Automated outreach and customer engagement",
                    is_active=True,
                )
                db.add(new_product)
                db.commit()
                db.refresh(new_product)
                active_product = new_product
                action_type = "PRODUCT_CREATED"
                action_data = {"product_id": new_product.id, "name": new_product.name}

                # Try to scrape website if provided
                if website:
                    try:
                        scrape_res = await knowledge_extractor.scrape_website(website)
                        if scrape_res.get("success"):
                            active_product.knowledge_base = scrape_res.get("summary", "")
                            db.commit()
                    except Exception:
                        pass

                bot_reply += f"\n\nI have created your company profile for \"{company_name}\". I am now ready to find customers, run outreach, and handle follow-ups for you."
            except Exception as ex:
                logger.warning(f"Auto-create product failed: {ex}")

        elif "find" in lower_msg and ("customer" in lower_msg or "lead" in lower_msg or "prospect" in lower_msg):
            if active_product:
                discovered = await orchestrator.execute_prospecting_cycle(db, active_product.id, batch_size=3)
                action_type = "PROSPECTS_DISCOVERED"
                action_data = {"count": len(discovered), "leads": [l.name for l in discovered]}
                bot_reply += f"\n\nDiscovered {len(discovered)} qualified prospects matching your ICP. You can view them in the Pipeline tab."
            else:
                bot_reply += "\n\nI need your company details first. Please share your website URL, email, or phone number so I can set up your profile."

        elif extracted_info.get("telegram_handles") or extracted_info.get("emails"):
            # Auto-import detected contacts into leads pipeline
            imported_count = await self._auto_import_leads(db, extracted_info, active_product)
            if imported_count > 0:
                action_type = "LEADS_IMPORTED"
                action_data = {"count": imported_count}

        elif extracted_info.get("website_url") and active_product:
            # Auto-sync website intelligence
            try:
                scrape_res = await knowledge_extractor.scrape_website(extracted_info["website_url"])
                if scrape_res.get("success"):
                    active_product.website_url = extracted_info["website_url"]
                    active_product.knowledge_base = scrape_res.get("summary", "")
                    db.commit()
            except Exception as ex:
                logger.warning(f"Auto-scrape failed: {ex}")

        orchestrator.log_activity(
            db,
            role="SalesAI Partner",
            action=f"Processed user command: {user_text[:60]}",
            details=bot_reply[:120],
            level="INFO"
        )

        return {
            "reply": bot_reply,
            "action_type": action_type,
            "action_data": action_data,
            "extracted_info": extracted_info
        }


    def _extract_entities(self, text: str) -> Dict[str, Any]:
        emails = re.findall(r"[\w\.-]+@[\w\.-]+\.\w+", text)
        phones = re.findall(r"[\+\(]?[0-9][0-9 \-\(\)]{7,}[0-9]", text)
        telegram_handles = re.findall(r"@([a-zA-Z0-9_]{3,32})", text)
        urls = re.findall(r"https?://[^\s]+", text)

        return {
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
                confidence_score=0.90,
                pain_points="Direct lead imported for daily follow-up and engagement",
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
                confidence_score=0.88,
                pain_points="Email contact imported for automated nurturing",
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
                return f"Understood. I have recorded your details. To complete onboarding, tell me your company name and primary product offering so I can begin prospecting."
            return "Hello. I am your 24/7 autonomous sales and marketing partner. Give me your email, phone number, company website, or product picture, and I will build your customer pipeline and handle outreach."

        if "find" in lower or "prospect" in lower or "customer" in lower:
            return f"Initiating autonomous customer discovery for {product.name}. I am scanning target industries and matching verified decision makers to your ICP."

        if "ad" in lower or "copy" in lower or "pitch" in lower:
            return f"Here is a direct cold outreach pitch crafted for {product.name}:\n\nSubject: Growth efficiency for your team\n\nHi [Name],\n\nSaw your recent milestones. Most teams face friction scaling outbound manually. {product.name} automates the entire pipeline so you close more deals with zero manual overhead.\n\nOpen to a brief 2-minute overview this week?"

        if "follow up" in lower or "check" in lower:
            return f"Scheduled automated follow-up sequence. I will send daily check-ins, product updates, and personalized touchpoints to your active leads."

        return f"Acknowledged. I am monitoring your sales pipeline for {product.name}. You can paste a list of Telegram handles or emails, ask me to find new leads, or command an outreach campaign."

    def _strip_emojis(self, text: str) -> str:
        emoji_pattern = re.compile(
            r"[\U00010000-\U0010ffff]|[\u2600-\u27ff]|[\u2300-\u23ff]|[\u2b50]|[\u3030]",
            flags=re.UNICODE
        )
        return emoji_pattern.sub("", text)

conversational_agent = ConversationalAgent()
