from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Literal
import os
import logging

import vertexai
# ✅ Impor `Content` yang dibutuhkan
from vertexai.generative_models import GenerativeModel, GenerationConfig, Part, Content

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
MODEL_NAME = os.environ.get("MODEL_NAME", "gemini-1.5-flash-001") # Using specific version is better
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
    # 'assistant' is a common name from client-side, maps to 'model' for Gemini
    role: Literal["user", "assistant", "system"]
    content: str


class ChatRequest(BaseModel):
    messages: List[ChatMessage]
    city: str = Field(default="Malang")


class ChatResponse(BaseModel):
    answer: str


SYSTEM_PROMPT = (
    "Anda adalah asisten virtual yang berpengetahuan luas tentang Kota Malang, Indonesia. "
    "Jawab pertanyaan dengan singkat, akurat, dan relevan dengan konteks Malang. "
    "Prioritaskan informasi tentang destinasi wisata, kuliner khas, rute transportasi, dan layanan publik di Malang. "
    "Jika pertanyaan di luar konteks Malang atau Anda tidak yakin dengan jawabannya, katakan saja Anda tidak tahu."
)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    # ✅ 1. Gabungkan system prompt dan fokus kota menjadi satu instruksi awal
    full_system_prompt = f"{SYSTEM_PROMPT}\n\nFokus percakapan ini hanya untuk kota: {req.city}."
    
    # ✅ 2. Gunakan objek `Content` dan `Part`, bukan dictionary.
    #    Ini adalah perbaikan utama untuk error TypeError Anda.
    #    Pola [user_prompt, model_response] baik untuk memulai percakapan.
    contents = [
        Content(role="user", parts=[Part.from_text(full_system_prompt)]),
        Content(role="model", parts=[Part.from_text("Baik, saya mengerti. Saya siap membantu dengan informasi seputar Kota Malang.")])
    ]

    for m in req.messages:
        # ✅ 3. Petakan peran 'assistant' dari request menjadi 'model' untuk API Gemini
        #    Peran 'system' diabaikan karena sudah ditangani di prompt awal
        if m.role == "system":
            continue
        role = "model" if m.role == "assistant" else "user"
        contents.append(Content(role=role, parts=[Part.from_text(m.content)]))
    
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
        # Use .text for safety, it handles cases where generation is blocked
        text = resp.text or ""
        return ChatResponse(answer=text)
    except Exception as e:
        logging.exception("Generation failed: %s", e)
        return ChatResponse(
            answer=(
                "Maaf, layanan sedang mengalami gangguan. Silakan coba lagi nanti.\n"
                f"(Detail teknis: {e})"
            )
        )