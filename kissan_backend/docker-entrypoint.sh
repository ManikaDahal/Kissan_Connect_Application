#!/bin/bash

# Exit on error
set -e

echo "Starting deployment checks..."

# Run migrations
echo "Running database migrations..."
python manage.py migrate --noinput

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Start Gunicorn
echo "Starting Gunicorn server on port 7860..."
exec gunicorn kissan_core.wsgi:application \
    --bind 0.0.0.0:7860 \
    --workers 3 \
    --timeout 120 \
    --access-log-file -