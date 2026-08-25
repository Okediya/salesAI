from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from backend.app.core.database import get_db
from backend.app.models.db_models import Product
from backend.app.models.schemas import ProductCreate, ProductResponse
from backend.app.agents.orchestrator import orchestrator
from backend.app.engine.taskmaster_loop import taskmaster_engine

router = APIRouter(prefix="/products", tags=["Products & ICP"])

@router.post("/", response_model=ProductResponse)
async def onboard_product(product_in: ProductCreate, db: Session = Depends(get_db)):
    """
    Onboards a startup/product, runs StrategyAgent to parse Product DNA and construct ICP.
    """
    product = await orchestrator.onboard_product(db, product_in)
    
    # Broadcast event to frontend
    await taskmaster_engine.broadcast_event("PRODUCT_ONBOARDED", {
        "id": product.id,
        "name": product.name,
        "icp_summary": product.icp_summary
    })
    return product

@router.get("/active", response_model=Optional[ProductResponse])
def get_active_product(db: Session = Depends(get_db)):
    """Returns the currently active product being worked on by SalesAI."""
    return db.query(Product).filter(Product.is_active == True).first()

@router.get("/", response_model=List[ProductResponse])
def list_products(db: Session = Depends(get_db)):
    return db.query(Product).order_by(Product.created_at.desc()).all()

@router.post("/{product_id}/activate", response_model=ProductResponse)
def activate_product(product_id: int, db: Session = Depends(get_db)):
    db.query(Product).update({Product.is_active: False})
    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    product.is_active = True
    db.commit()
    db.refresh(product)
    return product

@router.post("/{product_id}/sync-website")
async def sync_product_website(product_id: int, request: Optional[dict] = None, db: Session = Depends(get_db)):
    """
    Crawls and extracts live product intelligence from the startup website URL.
    """
    from datetime import datetime
    from backend.app.services.knowledge_extractor import knowledge_extractor

    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    target_url = (request.get("website_url") if request else None) or product.website_url
    if not target_url:
        raise HTTPException(status_code=400, detail="No website URL provided for scraping.")

    orchestrator.log_activity(
        db,
        role="StrategyAgent",
        action=f"Syncing live website intelligence from '{target_url}'",
        details="Crawling homepage and extracting features, pricing, and company news...",
        level="INFO"
    )

    scrape_result = await knowledge_extractor.scrape_website(target_url)
    product.website_url = target_url
    product.knowledge_base = scrape_result.get("summary", "")
    product.website_last_synced = datetime.utcnow()
    db.commit()
    db.refresh(product)

    orchestrator.log_activity(
        db,
        role="StrategyAgent",
        action=f"Knowledge Base Synchronized for '{product.name}'",
        details=f"Extracted {len(product.knowledge_base)} characters of live startup intelligence.",
        level="SUCCESS"
    )

    await taskmaster_engine.broadcast_event("KNOWLEDGE_BASE_SYNCED", {
        "product_id": product.id,
        "website_url": target_url,
        "knowledge_base": product.knowledge_base
    })

    return {
        "success": True,
        "product_id": product.id,
        "website_url": target_url,
        "extracted_knowledge_summary": product.knowledge_base,
        "synced_at": product.website_last_synced
    }

@router.post("/{product_id}/analyze-image")
async def analyze_product_image_endpoint(product_id: int, request: dict, db: Session = Depends(get_db)):
    """
    Analyzes uploaded product screenshots/images via Gemini 2.5 Flash Vision.
    """
    from backend.app.services.knowledge_extractor import knowledge_extractor

    product = db.query(Product).filter(Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")

    image_b64 = request.get("image_base64")
    if not image_b64:
        raise HTTPException(status_code=400, detail="image_base64 string is required")

    orchestrator.log_activity(
        db,
        role="StrategyAgent",
        action=f"Analyzing Product UI Screenshot with Gemini 2.5 Flash Vision",
        details="Deconstructing visual features, workflows, and dashboard components...",
        level="INFO"
    )

    analysis_res = await knowledge_extractor.analyze_product_image(image_b64, request.get("notes"))
    product.image_features = analysis_res.get("extracted_ui_features", "")
    db.commit()
    db.refresh(product)

    orchestrator.log_activity(
        db,
        role="StrategyAgent",
        action=f"Vision Analysis Complete for '{product.name}'",
        details="Extracted UI capabilities added to autonomous knowledge engine.",
        level="SUCCESS"
    )

    await taskmaster_engine.broadcast_event("IMAGE_ANALYZED", {
        "product_id": product.id,
        "image_features": product.image_features
    })

    return {
        "success": True,
        "product_id": product.id,
        "extracted_ui_features": product.image_features,
        "detected_capabilities": analysis_res.get("detected_capabilities", [])
    }

