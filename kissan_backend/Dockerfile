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

# Ensure the entrypoint is executable (must be done as root)
RUN chmod +x /app/docker-entrypoint.sh

# Create a non-root user (UID 1000 for Hugging Face) and give permissions
RUN useradd -m -u 1000 user && \
    chown -R user:user /app
USER user

# Expose the port
EXPOSE 7860

# Run entrypoint script
ENTRYPOINT ["/app/docker-entrypoint.sh"]