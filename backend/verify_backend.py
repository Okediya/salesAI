import asyncio
from backend.app.core.database import SessionLocal, Base, engine
from backend.app.models.schemas import ProductCreate
from backend.app.agents.orchestrator import orchestrator

async def test_full_pipeline():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        print("Testing Step 1: Product Onboarding & Strategy Analysis...")
        product_in = ProductCreate(
            name="ApexMetrics",
            tagline="AI-Powered Predictive Churn & Revenue Retention Engine",
            description="ApexMetrics continuously tracks customer engagement signals across Stripe, Intercom, and Mixpanel to predict customer churn 60 days in advance and trigger automated retention plays.",
            website_url="https://apexmetrics.io",
            target_market="Subscription B2B SaaS companies with $1M-$50M ARR",
            pricing_model="$499/month base + $100 per 1,000 tracked accounts",
            value_propositions="Reduces B2B churn by 35%, autonomous retention playbooks, real-time revenue hazard alerts"
        )
        product = await orchestrator.onboard_product(db, product_in)
        print(f"Product Created ID: {product.id}, Name: {product.name}")
        print(f"ICP Summary: {product.icp_summary}")

        print("\nTesting Step 2: Autonomous Prospecting Cycle...")
        leads = await orchestrator.execute_prospecting_cycle(db, product.id, batch_size=3)
        print(f"Discovered {len(leads)} leads:")
        for l in leads:
            print(f" - {l.name} ({l.role} at {l.company}) | Confidence: {l.confidence_score}")

        if leads:
            target_lead = leads[0]
            print(f"\nTesting Step 3: Copywriting Cycle for {target_lead.name}...")
            campaigns = await orchestrator.execute_campaign_generation(db, target_lead.id)
            print(f"Generated {len(campaigns)} campaign steps:")
            for c in campaigns:
                print(f" [{c.channel.value} Step {c.sequence_step}] Subject: {c.subject}")

            print(f"\nTesting Step 4: SDR Reply Analysis & Objection Handling...")
            test_reply = "We like what you're doing, but we currently use an in-house script. How easy is it to migrate?"
            sdr_result = await orchestrator.execute_sdr_reply_handling(db, target_lead.id, test_reply)
            print(f"Sentiment: {sdr_result.sentiment} | Intent: {sdr_result.intent_score}/100 | Action: {sdr_result.recommended_action}")
            print(f"Agent Reply:\n{sdr_result.suggested_reply}")

        print("\nALL BACKEND MULTI-AGENT WORKFLOWS PASSED!")
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(test_full_pipeline())
