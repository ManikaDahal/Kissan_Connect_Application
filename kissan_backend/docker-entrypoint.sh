#!/bin/sh

# Exit on error
set -e

echo "Starting deployment checks..."

# Wait for database to be ready (max 30 seconds)
echo "Waiting for database to be ready..."
MAX_RETRIES=10
RETRY=0
until python manage.py shell -c "from django.db import connection; connection.ensure_connection(); print('DB ready')" 2>/dev/null; do
    RETRY=$((RETRY+1))
    if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
        echo "ERROR: Database connection failed after $MAX_RETRIES retries. Exiting."
        exit 1
    fi
    echo "Database not ready yet. Retrying in 3 seconds... ($RETRY/$MAX_RETRIES)"
    sleep 3
done

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
    --workers 2 \
    --timeout 120 \
    --access-logfile -