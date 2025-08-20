from fastapi import FastAPI
from app.api.routes import router as api_router
from app.core.config import get_settings


settings = get_settings()
app = FastAPI(title=f"Hello World API ({settings.stage})")


@app.get("/health", tags=["health"])  # Optional health endpoint
async def health():
    return {"status": "ok", "stage": settings.stage}


# Root API routes
app.include_router(api_router)
