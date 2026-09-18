FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (layer caching)
COPY requirements.txt .
COPY requirements-postgres.txt .

# Install base + postgres driver
RUN pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir psycopg2-binary==2.9.9

# Copy application code
COPY . .

# Create instance directory
RUN mkdir -p /app/instance

# Environment
ENV FLASK_ENV=production
ENV PORT=5000

EXPOSE 5000

# Init DB then start gunicorn
CMD python wsgi.py || true && \
    gunicorn wsgi:app \
    --bind 0.0.0.0:${PORT} \
    --workers 2 \
    --threads 4 \
    --timeout 120 \
    --access-logfile - \
    --error-logfile -
