# Use an official Python runtime as a parent image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PORT 7860

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . /app/

# Create a non-root user (UID 1000 for Hugging Face) and give permissions
RUN useradd -m -u 1000 user && \
    chown -R user:user /app
USER user

# Expose the port
EXPOSE 7860

# Run migrations, collect static files, then start gunicorn
CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py collectstatic --noinput && exec gunicorn kissan_core.wsgi:application --bind 0.0.0.0:7860 --workers 2 --timeout 120 --access-logfile -"]