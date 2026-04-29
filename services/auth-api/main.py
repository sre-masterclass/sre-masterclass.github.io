from datetime import timedelta
from typing import List, Optional
from pydantic import BaseModel
from fastapi import Depends, FastAPI, HTTPException, status, Response
from fastapi.security import OAuth2PasswordRequestForm
import asyncio
import random

import security
from models import Token, User
from prometheus_fastapi_instrumentator import Instrumentator

app = FastAPI()

Instrumentator().instrument(app).expose(app)

# In-memory store for entropy state
entropy_state = {"latency": 0, "error_rate": 0}

class LatencyPayload(BaseModel):
    latency: float

class ErrorRatePayload(BaseModel):
    error_rate: float

@app.middleware("http")
async def entropy_middleware(request, call_next):
    # Introduce latency
    if entropy_state["latency"] > 0:
        await asyncio.sleep(entropy_state["latency"])

    # Introduce errors
    if random.random() < entropy_state["error_rate"]:
        return Response("Internal Server Error", status_code=500)

    response = await call_next(request)
    return response

@app.post("/entropy/latency")
async def set_latency(payload: LatencyPayload):
    entropy_state["latency"] = payload.latency
    return {"message": f"Latency set to {payload.latency}"}

@app.post("/entropy/errors")
async def set_error_rate(payload: ErrorRatePayload):
    entropy_state["error_rate"] = payload.error_rate
    return {"message": f"Error rate set to {payload.error_rate}"}

@app.post("/token")
async def login_for_access_token(response: Response, form_data: OAuth2PasswordRequestForm = Depends()):
    user_in_db = security.get_user(security.fake_users_db, form_data.username)
    if not user_in_db or not security.verify_password(form_data.password, user_in_db.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        data={"sub": user_in_db.username}, expires_delta=access_token_expires
    )
    response.set_cookie(key="access_token", value=access_token, httponly=True)
    return {"message": "Login successful"}


@app.get("/users/me", response_model=User)
async def read_users_me(current_user: User = Depends(security.get_current_active_user)):
    return current_user


@app.get("/health")
def health_check():
    return {"status": "ok"}


@app.get("/")
def read_root():
    return {"Hello": "Auth API"}
