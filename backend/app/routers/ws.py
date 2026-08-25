import logging
from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from backend.app.engine.taskmaster_loop import taskmaster_engine

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/ws", tags=["Real-time Live Telemetry"])

@router.websocket("/telemetry")
async def websocket_telemetry_endpoint(websocket: WebSocket):
    await websocket.accept()
    taskmaster_engine.register_ws(websocket)
    logger.info("Flutter UI connected to real-time telemetry stream.")
    
    # Send initial handshake message
    await websocket.send_json({
        "event": "CONNECTED",
        "message": "Connected to SalesAI 24/7 Live Telemetry Feed",
        "agent_running": taskmaster_engine.is_running,
        "autonomy_mode": taskmaster_engine.autonomy_mode.value
    })

    try:
        while True:
            # Keep connection alive and listen for client messages (e.g. ping/heartbeat)
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        taskmaster_engine.unregister_ws(websocket)
        logger.info("Flutter UI disconnected from telemetry stream.")
    except Exception as e:
        logger.debug(f"WS connection closed: {e}")
        taskmaster_engine.unregister_ws(websocket)
