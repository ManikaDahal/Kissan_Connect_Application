#!/usr/bin/env bash
# exit on error
set -o errexit

pip install -r requirements.txt

# collect static files
echo "Collecting static files..."
python manage.py collectstatic --no-input --clear

# Run migrations
echo "Running migrations..."
python manage.py migrate --no-input

# Create superuser if it doesn't exist
echo "Creating superuser if it doesn't exist..."
python manage.py shell <<EOF
from users.models import User
import os
email = os.environ.get('ADMIN_EMAIL', 'admin@example.com')
password = os.environ.get('ADMIN_PASSWORD', 'AdminPassword123')
if not User.objects.filter(email=email).exists():
    User.objects.create_superuser(
        email=email,
        password=password,
        full_name='Admin User'
    )
    print(f'Superuser {email} created.')
else:
    print(f'Superuser {email} already exists.')
EOF
