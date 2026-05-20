from fastapi import FastAPI, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
import os
from contextlib import asynccontextmanager
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
import time

from .database import engine, Base
from . import models
from .routers import leagues, matches, news, players, teams, admin, auth, user_feedback, stadiums, coaches, proxy
from .dependencies import limiter, check_ip_ban, get_db
from sqlalchemy.exc import OperationalError, ProgrammingError


# ─── Database Init ───────────────────────────────────────────
def init_db():
    retries = 10
    while retries > 0:
        try:
            Base.metadata.create_all(bind=engine)
            print("✅ Database tables created successfully!")
            return True
        except Exception as e:
            print(f"⏳ Waiting for MySQL... ({retries} retries left). Error: {e}")
            time.sleep(5)
            retries -= 1
    return False


db_ready = init_db()

if db_ready:
    try:
        from .seed_v2 import seed_v2
        seed_v2()
    except Exception as e:
        print(f"⚠️ Seeding warning: {e}")


# ─── App Lifespan ────────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("🚀 Application starting up...")
    yield
    print("🛑 Application shutting down...")


# ─── FastAPI App ─────────────────────────────────────────────
app = FastAPI(
    title="Clasico API",
    description=(
        "Backend API for the Clasico application. "
        "Admin Panel endpoints require Bearer JWT authentication with appropriate roles."
    ),
    version="2.0.0",
    lifespan=lifespan,
    dependencies=[Depends(check_ip_ban)],
)

os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

# ─── Rate Limiting Middleware ─────────────────────────────────
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# ─── CORS ────────────────────────────────────────────────────
# IMPORTANT: You cannot use allow_origins=["*"] together with allow_credentials=True.
# Browsers will block such responses. Use explicit origins instead.
# We allow all localhost ports to support Flutter web development on any port.
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://localhost(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# ─── Routers ─────────────────────────────────────────────────
app.include_router(auth.router)
app.include_router(leagues.router)
app.include_router(matches.router)
app.include_router(news.router)
app.include_router(players.router)
app.include_router(teams.router)
app.include_router(stadiums.router)
app.include_router(coaches.router)
app.include_router(proxy.router)
app.include_router(user_feedback.router)
app.include_router(admin.router)


# ─── Root ────────────────────────────────────────────────────
@app.get("/", tags=["Health"])
def read_root():
    return {
        "message": "Welcome to Clasico API",
        "version": "2.0.0",
        "docs": "/docs",
        "admin_docs": "All admin endpoints are under /admin/* and require JWT + role",
    }


@app.get("/health", tags=["Health"])
def health_check():
    return {"status": "ok"}


# ─── Global Exception Handler ──────────────────────────────────
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    # This ensures that even on 500 errors, the response is structured
    # and CORS headers (added by middleware) are processed correctly.
    print(f"🔥 Global Error: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "detail": "Internal Server Error",
            "error": str(exc),
            "type": type(exc).__name__
        },
    )
