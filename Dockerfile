# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization (production-ready)
# ═══════════════════════════════════════════════════════════════════

# ---------- Stage 1: builder ----------
FROM python:3.11-slim AS builder

WORKDIR /build

# Copy requirements trước để tận dụng layer cache:
# sửa code không phải cài lại thư viện.
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ---------- Stage 2: runtime ----------
FROM python:3.11-slim AS runtime

WORKDIR /app

# Chỉ mang thư viện đã cài sang, không mang theo cache/compiler
COPY --from=builder /install /usr/local

# Chỉ copy source cần chạy
COPY app/ ./app/
COPY utils/ ./utils/

# Tạo user thường, không chạy bằng root
RUN useradd --create-home --shell /usr/sbin/nologin appuser
USER appuser

# Cloud tự gán PORT; 8000 chỉ là mặc định khi chạy ở máy
ENV PORT=8000 \
    PYTHONUNBUFFERED=1
EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import os,urllib.request; urllib.request.urlopen('http://localhost:'+os.environ.get('PORT','8000')+'/health')"

# Bind 0.0.0.0 và đọc cổng từ ${PORT}
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]