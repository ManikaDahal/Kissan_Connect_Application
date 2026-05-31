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

# Copy project
COPY . /app/

# Create a non-root user and switch to it
# Hugging Face Spaces run with UID 1000
RUN useradd -m -u 1000 user
USER user

# Make entrypoint script executable
# Note: Since we are switching to user 1000, we ensure the file is owned by them or executable
# Actually, COPY might need --chown=user:user
COPY --chown=user:user . /app/

RUN chmod +x /app/docker-entrypoint.sh

# Expose the port
EXPOSE 7860

# Run entrypoint script
ENTRYPOINT ["/app/docker-entrypoint.sh"]
