import math
import re
from typing import Iterable, List, Optional, Tuple

from django.db.models import QuerySet

from .models import Product


POSITIVE_WORDS = {
    'good', 'great', 'excellent', 'amazing', 'love', 'best', 'nice', 'fast', 'fresh',
    'high', 'quality', 'happy', 'satisfied', 'perfect', 'awesome', 'worth', 'recommended',
    'helpful', 'clean', 'reliable', 'smooth', 'affordable', 'delicious', 'healthy', 'fantastic'
}
NEGATIVE_WORDS = {
    'bad', 'poor', 'awful', 'terrible', 'hate', 'worst', 'slow', 'damaged', 'broken',
    'late', 'dirty', 'cheap', 'unreliable', 'expensive', 'disappointing', 'badly', 'issue',
    'problem', 'faulty', 'poorly', 'ruined', 'wrong', 'fake'
}


def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Return distance in kilometers between two coordinates using the Haversine formula."""
    if None in (lat1, lon1, lat2, lon2):
        return float('inf')

    radius = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lon2 - lon1)

    a = (
        math.sin(delta_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return radius * c


def get_nearby_products(lat: float, lon: float, radius_km: float = 20, limit: int = 10, queryset: Optional[QuerySet] = None) -> List[Product]:
    """Return approved products whose seller location is within the given radius."""
    if queryset is None:
        queryset = Product.objects.select_related('category', 'seller', 'seller__seller_profile').filter(approval_status='approved')

    products_with_distance = []
    for product in queryset:
        seller_profile = getattr(product.seller, 'seller_profile', None)
        if not seller_profile or seller_profile.latitude is None or seller_profile.longitude is None:
            continue
        distance = haversine_distance(lat, lon, seller_profile.latitude, seller_profile.longitude)
        if distance <= radius_km:
            products_with_distance.append((product, distance))

    products_with_distance.sort(key=lambda item: item[1])
    return [product for product, _ in products_with_distance[:limit]]


def build_product_vector(product: Product) -> List[float]:
    """Create a lightweight vector for simple cosine-similarity recommendations."""
    category_id = float(product.category_id or 0)
    price_score = 1.0 / (1.0 + float(product.price or 0))
    rating_score = float(product.average_rating or 0) / 5.0
    discount_score = 1.0 if product.discount_price is not None else 0.0
    famous_score = 1.0 if product.is_famous else 0.0
    return [category_id, price_score, rating_score, discount_score, famous_score]


def cosine_similarity(vec_a: Iterable[float], vec_a2: Iterable[float]) -> float:
    """Return cosine similarity between two vectors."""
    left = list(vec_a)
    right = list(vec_a2)
    if not left or not right:
        return 0.0

    dot_product = sum(x * y for x, y in zip(left, right))
    norm_a = math.sqrt(sum(x * x for x in left))
    norm_b = math.sqrt(sum(y * y for y in right))
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return dot_product / (norm_a * norm_b)


def get_recommended_products(product_id: Optional[int] = None, limit: int = 6, queryset: Optional[QuerySet] = None) -> List[Product]:
    """Recommend related products using cosine similarity over simple product features."""
    if queryset is None:
        queryset = Product.objects.select_related('category', 'seller', 'seller__seller_profile').filter(approval_status='approved')

    products = list(queryset)
    if not products:
        return []

    if product_id is not None:
        target_product = next((product for product in products if product.id == product_id), None)
        if target_product is None:
            return products[:limit]
        target_vector = build_product_vector(target_product)
        scored_products = []
        for product in products:
            if product.id == product_id:
                continue
            similarity = cosine_similarity(target_vector, build_product_vector(product))
            if similarity > 0:
                scored_products.append((product, similarity))
        scored_products.sort(key=lambda item: item[1], reverse=True)
        return [product for product, _ in scored_products[:limit]]

    return sorted(products, key=lambda product: (product.average_rating, product.created_at), reverse=True)[:limit]


def analyze_sentiment(text: Optional[str]) -> dict:
    """Return a simple polarity-based sentiment summary for review comments."""
    if not text:
        return {'label': 'neutral', 'score': 0.0}

    words = re.findall(r"[a-zA-Z']+", text.lower())
    score = 0
    for word in words:
        if word in POSITIVE_WORDS:
            score += 1
        elif word in NEGATIVE_WORDS:
            score -= 1

    if score > 0:
        label = 'positive'
    elif score < 0:
        label = 'negative'
    else:
        label = 'neutral'

    return {'label': label, 'score': round(score / max(1, len(words)), 3)}
