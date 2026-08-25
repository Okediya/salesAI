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
