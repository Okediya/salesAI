import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from backend.app.core.config import settings
from backend.app.core.database import init_db
from backend.app.routers import products, leads, campaigns, agent, ws
from backend.app.engine.taskmaster_loop import taskmaster_engine

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("SalesAI")

# Create database tables + auto-migrate new columns
init_db()

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing SalesAI 24/7 Agent Application...")
    # Start autonomous background loop
    await taskmaster_engine.start()
    yield
    logger.info("Shutting down SalesAI...")
    await taskmaster_engine.stop()

app = FastAPI(
    title="SalesAI - 24/7 Autonomous Sales & Marketing Agent",
    description="Backend API for the Google Agentic Hackathon (TaskMaster Track). Powered by Google Gemini & ADK.",
    version="1.0.0",
    lifespan=lifespan
)

# Enable CORS for Flutter web / desktop / mobile connections
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routers
app.include_router(products.router)
app.include_router(leads.router)
app.include_router(campaigns.router)
app.include_router(agent.router)
app.include_router(ws.router)

@app.get("/")
def root():
    return {
        "app": "SalesAI",
        "tagline": "24/7 Autonomous Sales & Marketing Agent",
        "track": "TaskMaster Track (Google Agentic Hackathon)",
        "status": "ONLINE",
        "docs_url": "/docs"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("backend.main:app", host=settings.HOST, port=settings.PORT, reload=True)
