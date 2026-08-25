import asyncio
import base64
from backend.app.core.database import SessionLocal, init_db
from backend.app.models.schemas import ProductCreate
from backend.app.agents.orchestrator import orchestrator
from backend.app.services.knowledge_extractor import knowledge_extractor
from backend.app.services.delivery_service import delivery_service

async def test_full_pipeline():
    init_db()
    db = SessionLocal()
    try:
        print("Testing Step 1: Multimodal Knowledge Extraction (Website & Vision)...")
        scrape_res = await knowledge_extractor.scrape_website("https://example.com")
        print(f"Scraped Website Summary ({len(scrape_res['summary'])} chars): {scrape_res['summary'][:120]}...")

        # Small 1x1 transparent PNG sample in base64
        sample_png_b64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
        vision_res = await knowledge_extractor.analyze_product_image(sample_png_b64, "Dashboard with user retention metrics")
        print(f"Vision Analysis Capabilities: {vision_res['detected_capabilities']}")

        print("\nTesting Step 2: Product Onboarding & Strategy Analysis...")
        product_in = ProductCreate(
            name="ApexMetrics",
            tagline="AI-Powered Predictive Churn & Revenue Retention Engine",
            description="ApexMetrics continuously tracks customer engagement signals across Stripe, Intercom, and Mixpanel to predict customer churn 60 days in advance and trigger automated retention plays.",
            website_url="https://apexmetrics.io",
            target_market="Subscription B2B SaaS companies with $1M-$50M ARR",
            pricing_model="$499/month base + $100 per 1,000 tracked accounts",
            value_propositions="Reduces B2B churn by 35%, autonomous retention playbooks, real-time revenue hazard alerts",
            knowledge_base=scrape_res['summary'],
            image_features=vision_res['extracted_ui_features'],
            telegram_handle="apexmetrics_bot"
        )
        product = await orchestrator.onboard_product(db, product_in)
        print(f"Product Created ID: {product.id}, Name: {product.name}")
        print(f"ICP Summary: {product.icp_summary}")

        print("\nTesting Step 3: Autonomous Prospecting Cycle...")
        leads = await orchestrator.execute_prospecting_cycle(db, product.id, batch_size=3)
        print(f"Discovered {len(leads)} leads:")
        for l in leads:
            print(f" - {l.name} ({l.role} at {l.company}) | Confidence: {l.confidence_score}")

        if leads:
            target_lead = leads[0]
            target_lead.telegram_handle = "alex_founder"
            db.commit()

            print(f"\nTesting Step 4: Multichannel Copywriting Cycle for {target_lead.name} (Email, Telegram)...")
            campaigns = await orchestrator.execute_campaign_generation(db, target_lead.id)
            print(f"Generated {len(campaigns)} campaign steps:")
            for c in campaigns:
                print(f" [{c.channel.value} Step {c.sequence_step}] Subject: {c.subject}")

            print(f"\nTesting Step 5: Telegram & Email Delivery Service...")
            tg_res = await delivery_service.dispatch_telegram(
                telegram_handle=target_lead.telegram_handle,
                message="Hi Alex! Saw what you're building at your startup. Open to a 2-min demo?",
                lead_name=target_lead.name
            )
            print(f"Telegram Dispatch: {tg_res['message']} (Action URL: {tg_res['action_url']})")

            print(f"\nTesting Step 6: SDR Inbound Objection Handling using Continuous Knowledge...")
            test_reply = "Does ApexMetrics support automated retention playbooks for B2B SaaS?"
            sdr_result = await orchestrator.execute_sdr_reply_handling(db, target_lead.id, test_reply)
            print(f"Sentiment: {sdr_result.sentiment} | Intent: {sdr_result.intent_score}/100 | Action: {sdr_result.recommended_action}")
            print(f"Agent Reply:\n{sdr_result.suggested_reply}")

        print("\nALL BACKEND MULTI-AGENT WORKFLOWS PASSED!")
    finally:
        db.close()

if __name__ == "__main__":
    asyncio.run(test_full_pipeline())
