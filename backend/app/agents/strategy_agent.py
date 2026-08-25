import logging
from typing import Dict, Any
from backend.app.core.gemini_client import gemini_client
from backend.app.models.schemas import ProductStrategyAnalysis, ProductCreate

logger = logging.getLogger(__name__)

STRATEGY_SYSTEM_PROMPT = """
You are the Chief Sales & Marketing Strategist Agent for an autonomous B2B/B2C growth engine.
Your task is to analyze product/startup details, deconstruct the Product DNA, and construct an actionable Ideal Customer Profile (ICP).

You must identify:
1. Product DNA summary: core mechanism, value driver.
2. ICP Summary: precise definition of who needs this urgently.
3. Target Industries: 3-5 specific verticals.
4. Target Roles: specific job titles and decision-makers (e.g. "VP of Engineering", "Head of Sales", "Founder/CEO").
5. Core Value Propositions: 3 high-impact quantifiable outcomes.
6. Target Personas: Detailed breakdown of each persona, their acute pain point, gain, and trigger events.
7. Market Hooks: 3 punchy angles for cold outreach.
"""

class StrategyAgent:
    def __init__(self):
        self.client = gemini_client

    async def analyze_product(self, product_data: ProductCreate) -> ProductStrategyAnalysis:
        prompt = f"""
Analyze the following product/startup for autonomous sales and marketing:

Product Name: {product_data.name}
Tagline: {product_data.tagline or 'N/A'}
Description: {product_data.description}
Website: {product_data.website_url or 'N/A'}
Target Market Notes: {product_data.target_market or 'N/A'}
Pricing Model: {product_data.pricing_model or 'N/A'}
Value Propositions: {product_data.value_propositions or 'N/A'}
Continuous Scraped Knowledge Base: {product_data.knowledge_base or 'N/A'}
Gemini Vision UI Analysis & Features: {product_data.image_features or 'N/A'}

Provide a rigorous strategic ICP breakdown.
"""
        fallback_data: Dict[str, Any] = {
            "product_dna_summary": f"{product_data.name} delivers high-efficiency automated solutions tailored to relieve operational bottlenecks.",
            "icp_summary": f"High-growth startups and B2B scale-ups seeking to accelerate revenue and reduce manual overhead.",
            "target_industries": ["B2B SaaS", "E-commerce & Retail Tech", "Enterprise Software", "Fintech"],
            "target_roles": ["Founder / CEO", "VP of Sales", "Head of Growth", "Chief Technology Officer"],
            "core_value_props": [
                "Accelerates pipeline velocity by 3x with autonomous execution",
                "Reduces manual outreach and prospecting time by over 80%",
                "Delivers continuous, hyper-personalized multichannel touchpoints 24/7"
            ],
            "personas": [
                {
                    "role_title": "Founder & CEO",
                    "seniority": "Executive",
                    "core_pain_point": "Struggling to scale outbound sales without hiring expensive headcount",
                    "primary_gain": "Immediate autonomous lead generation and pipeline predictability",
                    "trigger_events": ["Recent funding announcement", "Rapid hiring spree", "Product launch"]
                },
                {
                    "role_title": "VP of Growth / Sales",
                    "seniority": "Director / VP",
                    "core_pain_point": "Low cold outreach conversion and inconsistent lead qualification",
                    "primary_gain": "Hyper-personalized messaging at scale with automated objection handling",
                    "trigger_events": ["Quarterly target missed", "Entering new market segment"]
                }
            ],
            "market_hooks": [
                "Autonomous 24/7 sales agent driving pipeline while your team sleeps",
                "Cut customer acquisition costs in half with AI-driven hyper-personalization",
                "Turn cold prospects into booked demos on pure autopilot"
            ]
        }

        try:
            result = await self.client.generate_structured(
                prompt=prompt,
                system_instruction=STRATEGY_SYSTEM_PROMPT,
                response_model=ProductStrategyAnalysis,
                fallback_data=fallback_data
            )
            return result
        except Exception as e:
            logger.error(f"StrategyAgent analysis error: {e}")
            return ProductStrategyAnalysis.model_validate(fallback_data)

strategy_agent = StrategyAgent()
