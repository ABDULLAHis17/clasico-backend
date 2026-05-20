# --- Stage 1: Build dependencies ---
FROM python:3.11-alpine AS builder

RUN apk add --no-cache build-base libffi-dev

WORKDIR /install

COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install/deps -r requirements.txt

# --- Stage 2: Runtime ---
FROM python:3.11-alpine

RUN apk add --no-cache libffi

WORKDIR /app

COPY --from=builder /install/deps /usr/local

COPY . .

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
