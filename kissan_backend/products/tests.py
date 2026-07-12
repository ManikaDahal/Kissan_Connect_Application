from django.test import TestCase

from .services import analyze_sentiment, cosine_similarity, haversine_distance


class RecommendationServiceTests(TestCase):
    def test_haversine_distance_returns_expected_value(self):
        distance = haversine_distance(27.7172, 85.3240, 27.7000, 85.3000)
        self.assertGreater(distance, 0)

    def test_cosine_similarity_handles_simple_vectors(self):
        self.assertAlmostEqual(cosine_similarity([1, 0, 1], [1, 0, 1]), 1.0)

    def test_analyze_sentiment_detects_positive_text(self):
        result = analyze_sentiment('This product is great and amazing')
        self.assertEqual(result['label'], 'positive')
        self.assertGreater(result['score'], 0)
