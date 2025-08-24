# Malang Chat Backend (Python + FastAPI on Cloud Run)

Backend sederhana untuk tanya-jawab seputar Kota Malang menggunakan Vertex AI (Gemini).

## 1) Prasyarat
- gcloud SDK terpasang dan sudah `gcloud auth login`
- Project GCP aktif
- Enable API:
  - Vertex AI API
  - Cloud Run Admin API
  - Artifact Registry API (opsional)

## 2) Deploy ke Cloud Run
Dari folder `backend/`:

```bash
PROJECT_ID=<your-project-id>
REGION=asia-southeast2
SERVICE=malang-chat-backend

gcloud config set project "$PROJECT_ID"

gcloud run deploy "$SERVICE" \
  --source . \
  --region "$REGION" \
  --set-env-vars PROJECT_ID=$PROJECT_ID,LOCATION=$REGION,MODEL_NAME=gemini-1.5-flash,TEMPERATURE=0.6,MAX_TOKENS=512,TOP_P=0.9,TOP_K=40 \
  --allow-unauthenticated
```

Catat URL layanan hasil deploy (misal: https://malang-chat-backend-xxxx.a.run.app)

## 3) Uji Lokal/Remote
- Health check:
```bash
curl -s https://<CLOUD_RUN_URL>/health
```

- Chat:
```bash
curl -s -X POST https://<CLOUD_RUN_URL>/chat \
  -H 'Content-Type: application/json' \
  -d '{
    "messages": [{"role": "user", "content": "Tempat wisata keluarga di Malang?"}],
    "city": "Malang"
  }' | jq
```

## 4) Integrasi Flutter (ringkas)
- Tambah dependency http di `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.2.2
```
- Panggil endpoint di `ChatPage` ketika send:
```dart
final res = await http.post(
  Uri.parse('<CLOUD_RUN_URL>/chat'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'messages': _messages.map((m) => {
      'role': m['isBot'] == true ? 'assistant' : 'user',
      'content': m['text'],
    }).toList(),
    'city': 'Malang',
  }),
);
final answer = json.decode(res.body)['answer'];
```

## 5) Keamanan (lanjutan)
- Untuk produksi, hilangkan `--allow-unauthenticated` dan gunakan ID token (IAP/Cloud Run auth) atau API Gateway.
- Set env vars melalui Cloud Run console/terraform untuk konsistensi.

## 6) Konfigurasi Model
- Ubah `MODEL_NAME` ke versi lain jika diperlukan (misal `gemini-1.5-pro`).
- Tuning parameter: `TEMPERATURE`, `MAX_TOKENS`, `TOP_P`, `TOP_K` lewat env.
