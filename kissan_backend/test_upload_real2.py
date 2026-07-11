import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'kissan_core.settings')
django.setup()

from users.models import User
from rest_framework.test import APIClient

user = User.objects.filter(role='seller').first()
if not user:
    print("No seller user found")
    exit()

client = APIClient()
client.force_authenticate(user=user)

with open('test.jpg', 'rb') as img:
    data = {
        'name': 'Test Upload',
        'description': 'desc',
        'price': 100.0,
        'stock': 10,
        'weight': 1,
        'category': 1,
        'unit_type': 'piece',
        'image': img
    }
    res = client.post('/api/products/seller/my-items/', data, format='multipart')

print(res.status_code)
print(res.data)
