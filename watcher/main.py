import logging
from fastapi import FastAPI, HTTPException, Query
from .watcher_service import WatcherService
from .config import settings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("tazkarti.main")

app = FastAPI(
    title="Tazkarti Football Tickets Alert Service",
    description="Alerts on Al Ahly and Egypt National Team match tickets on tazkarti.com",
    version="1.0.0"
)

watcher_service = WatcherService()


@app.get("/")
def root():
    return {
        "status": "online",
        "service": "Tazkarti Football Tickets Alert Watcher",
        "mock_mode": settings.mock_mode,
        "seed_silently": settings.seed_silently,
    }


@app.get("/health")
def health():
    return {"status": "ok"}


@app.api_route("/poll", methods=["GET", "POST"])
def poll():
    """Triggered by Cloud Scheduler or external cron to poll Tazkarti."""
    try:
        result = watcher_service.run_poll()
        return {"status": "success", "data": result}
    except Exception as exc:
        logger.error(f"Poll endpoint error: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


@app.api_route("/test-notification", methods=["GET", "POST"])
def test_notification(team: str = Query("egypt", regex="^(egypt|ahly)$")):
    """Sends a test push notification to verify lock screen and heads-up popups on your phone."""
    try:
        msg_id = watcher_service.force_test_notification(team)
        return {
            "status": "success",
            "message": f"Sent test push notification for {team} to topic {team}_tickets",
            "message_id": msg_id,
        }
    except Exception as exc:
        logger.error(f"Test notification error: {exc}")
        raise HTTPException(status_code=500, detail=str(exc))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("watcher.main:app", host="0.0.0.0", port=settings.port, reload=True)
