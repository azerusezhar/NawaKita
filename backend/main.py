from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Literal
import os
import logging

import vertexai
from vertexai.generative_models import GenerativeModel, GenerationConfig, Part

app = FastAPI(title="Malang Chat Backend", version="0.1.0")

# CORS for Flutter web/local dev and Cloud Run
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten later if needed
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Config via env
PROJECT_ID = os.environ.get("PROJECT_ID")
LOCATION = os.environ.get("LOCATION", "asia-southeast2")
MODEL_NAME = os.environ.get("MODEL_NAME", "gemini-1.5-flash")
TEMPERATURE = float(os.environ.get("TEMPERATURE", "0.6"))
MAX_TOKENS = int(os.environ.get("MAX_TOKENS", "512"))
TOP_P = float(os.environ.get("TOP_P", "0.9"))
TOP_K = int(os.environ.get("TOP_K", "40"))

# Initialize Vertex AI client lazily in startup event to avoid cold issues
@app.on_event("startup")
def on_startup():
    logging.basicConfig(level=logging.INFO)
    if not PROJECT_ID:
        logging.warning("PROJECT_ID is not set. Vertex AI calls will fail.")
    try:
        vertexai.init(project=PROJECT_ID, location=LOCATION)
        logging.info("Vertex AI initialized for project=%s location=%s", PROJECT_ID, LOCATION)
    except Exception as e:
        logging.exception("Failed to initialize Vertex AI: %s", e)


def _model():
    # Create model instance per request is fine (lightweight)
    return GenerativeModel(MODEL_NAME)


class ChatMessage(BaseModel):
    role: Literal["user", "assistant", "system"]
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    city: str = Field(default="Malang")


class ChatResponse(BaseModel):
    answer: str


SYSTEM_PROMPT = (
    "Anda asisten untuk Kota Malang. Jawab singkat, akurat, dan kontekstual. "
    "Prioritaskan informasi lokal Malang (destinasi, kuliner, transportasi, layanan publik). "
    "Jika tidak yakin, katakan tidak tahu."
)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    # Build contents: system + history + city focus
    contents = []
    contents.append({"role": "user", "parts": [Part.from_text(SYSTEM_PROMPT)]})
    for m in req.messages:
        contents.append({"role": m.role, "parts": [Part.from_text(m.content)]})
    contents.append({"role": "user", "parts": [Part.from_text(f"Fokus hanya kota: {req.city}.")]})
    try:
        resp = _model().generate_content(
            contents,
            generation_config=GenerationConfig(
                temperature=TEMPERATURE,
                max_output_tokens=MAX_TOKENS,
                top_p=TOP_P,
                top_k=TOP_K,
            ),
        )
        text = resp.text or ""
        return ChatResponse(answer=text)
    except Exception as e:
        logging.exception("Generation failed: %s", e)
        # Return friendly message with 200 to avoid client-side 500 UX
        return ChatResponse(
            answer=(
                "Maaf, layanan sedang bermasalah. Coba lagi beberapa saat.\n"
                "Detail teknis: " + str(e)
            )
        )
