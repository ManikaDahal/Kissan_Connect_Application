from django.db import models
from django.conf import settings
from cloudinary.models import CloudinaryField


UNIT_TYPE_CHOICES = [
    ('kg',     'Kilograms (kg)'),
    ('g',      'Grams (g)'),
    ('litre',  'Litres (L)'),
    ('ml',     'Millilitres (mL)'),
    ('piece',  'Piece / Item'),
    ('pack',   'Pack / Packet'),
    ('bag',    'Bag'),
    ('bottle', 'Bottle'),
    ('box',    'Box'),
]


class Category(models.Model):
    name = models.CharField(max_length=100, unique=True)
    image = CloudinaryField('image', null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class Product(models.Model):
    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='products', null=True, blank=True,
    )
    name = models.CharField(max_length=200)
    category = models.ForeignKey(Category, on_delete=models.CASCADE, related_name='products')
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2)
    stock = models.IntegerField(default=0)
    weight = models.DecimalField(
        max_digits=10, decimal_places=2, default=0.00,
        help_text="Numeric amount; meaning depends on unit_type (e.g. 500 mL, 1 kg, 100 g)",
    )
    unit_type = models.CharField(
        max_length=20, choices=UNIT_TYPE_CHOICES, default='piece',
        help_text="Unit of measurement for weight/volume/count",
    )
    image = CloudinaryField('image', null=True, blank=True)
    is_famous = models.BooleanField(default=False)
    discount_price = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True,
        help_text="Optional discounted price. If set, this price will be used instead of the normal price."
    )

    APPROVAL_STATUS_CHOICES = [
        ('pending',  'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]
    approval_status = models.CharField(
        max_length=15, choices=APPROVAL_STATUS_CHOICES, default='pending',
        help_text="Admin must approve before the product is visible to buyers."
    )
    admin_note = models.TextField(
        blank=True, null=True,
        help_text="Optional feedback shown to the seller on rejection."
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name

    @property
    def average_rating(self):
        reviews = self.reviews.all()
        if not reviews:
            return 0.0
        return sum(r.rating for r in reviews) / len(reviews)

    @property
    def total_reviews(self):
        return self.reviews.count()


class Review(models.Model):
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='reviews')
    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='reviews')
    rating = models.FloatField(default=5.0)
    comment = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.full_name} - {self.product.name} ({self.rating})"


class CategorySuggestion(models.Model):
    """A seller-suggested category that an admin must approve before it goes live."""

    STATUS_CHOICES = [
        ('pending',  'Pending Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE,
        related_name='category_suggestions',
    )
    name = models.CharField(max_length=100)
    reason = models.TextField(blank=True, help_text="Why do you need this category?")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    admin_note = models.TextField(blank=True, help_text="Admin feedback to seller")
    created_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} ({self.status}) — by {self.seller}"
