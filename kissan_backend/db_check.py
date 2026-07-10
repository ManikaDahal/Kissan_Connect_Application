import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'kissan_core.settings')
django.setup()

from products.models import Product

print("Total products:", Product.objects.count())
for p in Product.objects.all():
    print(f"ID: {p.id}, Name: {p.name}, Image: {p.image.url if p.image else None}")
