import logging
from typing import Dict, Any, List
from backend.app.core.gemini_client import gemini_client
from backend.app.models.schemas import CampaignCopyResult, OutreachSequenceItem
from backend.app.models.db_models import ChannelType

logger = logging.getLogger(__name__)

COPYWRITER_SYSTEM_PROMPT = """
You are the Elite AI Sales Copywriter Agent for SalesAI.
Your mission is to generate high-converting, hyper-personalized, non-spammy outreach sequences for multiple channels (Email, LinkedIn, X/Twitter).

Rules for high-converting sales copy:
1. Reference the prospect's company and specific pain point in the first sentence.
2. Focus on outcomes and value, not generic feature lists.
3. Keep emails under 120 words. Keep LinkedIn messages concise and conversational.
4. Provide clear, low-friction Calls to Action (CTA), e.g. "Open to seeing a 2-minute interactive demo?"
5. Produce a 3-step sequence: Step 1 (Hook), Step 2 (Value/Case Study), Step 3 (Low-friction Close).
"""

class CopywriterAgent:
    def __init__(self):
        self.client = gemini_client

    async def generate_outreach_sequence(
        self,
        product_name: str,
        product_description: str,
        value_propositions: List[str],
        lead_name: str,
        company: str,
        role: str,
        pain_points: str,
        personalization_hooks: str
    ) -> CampaignCopyResult:
        first_name = lead_name.split()[0] if lead_name else "there"
        prompt = f"""
Generate a 3-step multichannel personalized outreach sequence for:
Prospect: {lead_name} ({role} at {company})
Personalization Hook: {personalization_hooks}
Prospect Pain Points: {pain_points}

Product Being Sold: {product_name}
Product Value: {product_description}
Key Value Props: {', '.join(value_propositions) if value_propositions else 'Automated 24/7 revenue engine'}

Produce:
Step 1: Hyper-personalized initial cold email (with compelling subject)
Step 2: Follow-up value message (Email or LinkedIn)
Step 3: Quick conversational close / DM
"""

        fallback_data: Dict[str, Any] = {
            "lead_name": lead_name,
            "company": company,
            "hook_reason": f"Leveraging {company}'s current growth phase to alleviate {role} pain points.",
            "sequence": [
                {
                    "channel": "EMAIL",
                    "step_number": 1,
                    "subject": f"Quick thought on {company}'s pipeline growth, {first_name}?",
                    "body": f"Hi {first_name},\n\nI saw {personalization_hooks} and wanted to reach out. Many {role}s we speak with find that {pain_points.lower()}.\n\nWe built {product_name} to solve this directly by operating as a 24/7 autonomous growth engine—generating qualified pipeline with zero manual overhead.\n\nWorth a quick 5-min look this week?\n\nBest,\nSalesAI Team",
                    "call_to_action": "Open to a brief 5-min chat this Thursday?"
                },
                {
                    "channel": "EMAIL",
                    "step_number": 2,
                    "subject": f"How similar teams are solving this at {company}",
                    "body": f"Hi {first_name},\n\nFollowing up on my previous note. Teams similar to {company} used {product_name} to accelerate their outbound conversions by 3x within 14 days without expanding their headcount.\n\nThought this might be timely given your current growth targets.\n\nShould I send over a 2-minute overview video?",
                    "call_to_action": "Should I share the quick 2-minute overview video?"
                },
                {
                    "channel": "LINKEDIN",
                    "step_number": 3,
                    "subject": None,
                    "body": f"Hey {first_name} — noticed your leadership at {company}. If you're currently exploring ways to automate and supercharge outbound sales 24/7, {product_name} could be a game-changer for your team. Either way, love what you're building!",
                    "call_to_action": "Let me know if you'd like a quick preview!"
                }
            ]
        }

        try:
            result = await self.client.generate_structured(
                prompt=prompt,
                system_instruction=COPYWRITER_SYSTEM_PROMPT,
                response_model=CampaignCopyResult,
                fallback_data=fallback_data
            )
            return result
        except Exception as e:
            logger.error(f"CopywriterAgent error: {e}")
            return CampaignCopyResult.model_validate(fallback_data)

copywriter_agent = CopywriterAgent()
