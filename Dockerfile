FROM python:3.11-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=10000

# Copy requirements from watcher directory and install
COPY watcher/requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy watcher code
COPY watcher/ /app/watcher/

EXPOSE 10000

CMD ["sh", "-c", "uvicorn watcher.main:app --host 0.0.0.0 --port ${PORT:-10000}"]
