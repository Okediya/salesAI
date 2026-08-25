import logging
from typing import Dict, Any
from backend.app.core.gemini_client import gemini_client
from backend.app.models.schemas import SdrAnalysisResult

logger = logging.getLogger(__name__)

SDR_SYSTEM_PROMPT = """
You are the Autonomous AI SDR (Sales Development Representative) Agent for SalesAI.
Your role is to analyze prospect replies, score buying intent (0-100), identify objections, and craft high-converting objection-handling counter-replies.

Analysis criteria:
- POSITIVE (Intent > 75): Prospect wants a demo, pricing, or more info. Suggested action: PROCEED_TO_DEMO.
- SKEPTICAL (Intent 50-74): Prospect has questions or asks how it compares. Suggested action: SEND_CASE_STUDY.
- OBJECTION (Intent 30-49): Prospect raises specific hurdle (Budget, Timing, Already using competitor). Suggested action: OVERCOME_OBJECTION.
- NEGATIVE (Intent < 30): Prospect asks to unsubscribe or is clearly unqualified. Suggested action: DISQUALIFY or NURTURE.
"""

class SdrAgent:
    def __init__(self):
        self.client = gemini_client

    async def analyze_and_respond(
        self,
        product_name: str,
        lead_name: str,
        lead_company: str,
        incoming_message: str
    ) -> SdrAnalysisResult:
        first_name = lead_name.split()[0] if lead_name else "there"
        prompt = f"""
Analyze the following prospect reply:
Product Being Sold: {product_name}
Prospect: {lead_name} at {lead_company}
Incoming Message: "{incoming_message}"

Determine:
1. Sentiment (POSITIVE, SKEPTICAL, OBJECTION, NEGATIVE)
2. Intent Score (0-100)
3. Objection Type (Price, Timing, Competitor, Feature, Authority, None)
4. Recommended Action
5. Suggested Reply (Polite, concise, value-focused counter-response)
"""

        # Calibrate fallback based on simple keywords
        msg_lower = incoming_message.lower()
        if any(w in msg_lower for w in ["demo", "interested", "pricing", "call", "schedule", "sounds good", "yes"]):
            sentiment = "POSITIVE"
            intent = 88.0
            action = "PROCEED_TO_DEMO"
            obj_type = None
            reply = f"Hi {first_name},\n\nGlad to hear that! Here is a direct link to book a quick 10-minute walk-through: [Calendar Link]. Looking forward to connecting with the {lead_company} team!\n\nBest,\nSalesAI"
        elif any(w in msg_lower for w in ["expensive", "budget", "cost", "price"]):
            sentiment = "OBJECTION"
            intent = 45.0
            action = "OVERCOME_OBJECTION"
            obj_type = "Price"
            reply = f"Hi {first_name},\n\nCompletely understand that budget is top of mind. We designed {product_name} specifically with flexible tiering to deliver positive ROI within the first 30 days. Would you be open to seeing a quick breakdown of how our customers offset the cost?"
        elif any(w in msg_lower for w in ["not now", "busy", "next quarter", "later"]):
            sentiment = "OBJECTION"
            intent = 40.0
            action = "NURTURE"
            obj_type = "Timing"
            reply = f"Thanks for letting me know, {first_name}. I will follow up with you next quarter. In the meantime, I'll send over a 1-page case study on how we help companies in {lead_company}'s space."
        elif any(w in msg_lower for w in ["unsubscribe", "remove", "not interested", "stop"]):
            sentiment = "NEGATIVE"
            intent = 10.0
            action = "DISQUALIFY"
            obj_type = None
            reply = f"Understood, {first_name}. I have updated your preferences and removed you from our list. Wishing you and {lead_company} all the best!"
        else:
            sentiment = "SKEPTICAL"
            intent = 60.0
            action = "SEND_CASE_STUDY"
            obj_type = "Feature"
            reply = f"Hi {first_name},\n\nGreat question. {product_name} operates autonomously 24/7 with human-in-the-loop oversight. Happy to share a quick 2-minute overview showing exact numbers from teams similar to {lead_company}."

        fallback_data: Dict[str, Any] = {
            "sentiment": sentiment,
            "intent_score": intent,
            "objection_type": obj_type,
            "recommended_action": action,
            "suggested_reply": reply,
            "confidence": 0.92
        }

        try:
            result = await self.client.generate_structured(
                prompt=prompt,
                system_instruction=SDR_SYSTEM_PROMPT,
                response_model=SdrAnalysisResult,
                fallback_data=fallback_data
            )
            return result
        except Exception as e:
            logger.error(f"SdrAgent error: {e}")
            return SdrAnalysisResult.model_validate(fallback_data)

sdr_agent = SdrAgent()
