import 'package:flutter/material.dart';
import 'package:kissan_connect/theme/app_theme.dart';
import 'package:kissan_connect/widgets/product_card.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissan_connect/core/providers/cart_provider.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final dynamic product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _similarProducts = [];
  bool _isLoadingSimilar = true;
  final TextEditingController _reviewController = TextEditingController();
  int _selectedRating = 5;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSimilarProducts();
  }

  Future<void> _fetchSimilarProducts() async {
    try {
      final categoryId = widget.product['category'];
      if (categoryId != null) {
        final data = await ApiService.get('products/products/', params: {
          'category': categoryId.toString(),
        });
        if (mounted) {
          setState(() {
            _similarProducts = (data['results'] as List)
                .where((p) => p['id'] != widget.product['id'])
                .toList();
            _isLoadingSimilar = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSimilar = false);
    }
  }

  Future<void> _submitReview() async {
    if (_reviewController.text.isEmpty) return;
    
    try {
      await ApiService.post('products/reviews/', {
        'product': widget.product['id'],
        'rating': _selectedRating,
        'comment': _reviewController.text,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted successfully!")),
        );
        _reviewController.clear();
        // Refresh logic would go here if needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final price = product['price'];
    final weight = product['weight'] ?? "0.00";
    final stock = product['stock'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Scrollable Content
          CustomScrollView(
            slivers: [
              // 1. Header Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: const Color(0xFFE8F5E9),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.favorite_border, color: Colors.black87),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(color: const Color(0xFFE8F5E9)), // Light green bg like the photo
                      Hero(
                        tag: 'product-${product['id']}',
                        child: product['image'] != null
                            ? Image.network(product['image'], fit: BoxFit.contain, height: 200)
                            : const Icon(Icons.shopping_bag, size: 100, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Info Section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                          tabs: const [
                            Tab(text: "Details"),
                            Tab(text: "Reviews"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tab Content Area
                      SizedBox(
                        height: 400, // Fixed height for tab area to work in ScrollView
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Details Tab
                            _buildDetailsTab(product, weight, stock),
                            // Reviews Tab
                            _buildReviewsTab(product),
                          ],
                        ),
                      ),

                      // Similar Products
                      const SizedBox(height: 24),
                      Text("Similar Products", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _isLoadingSimilar
                          ? const Center(child: CircularProgressIndicator())
                          : _similarProducts.isEmpty
                              ? const Text("No similar products found.")
                              : SizedBox(
                                  height: 200,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _similarProducts.length,
                                    itemBuilder: (context, index) => ProductCard(
                                      product: _similarProducts[index],
                                      horizontal: true,
                                    ),
                                  ),
                                ),
                      const SizedBox(height: 100), // Spacing for bottom button
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 3. Sticky Add to Cart Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).addToCart(product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${product['name']} added to cart!")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Add to Cart", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Text("|", style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    const SizedBox(width: 8),
                    Text("Rs. $price", style: const TextStyle(fontSize: 18, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(dynamic product, dynamic weight, dynamic stock) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                product['name'],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              "Rs. ${product['price']}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSpecItem("Quantity Available", "$stock units"),
            const SizedBox(width: 40),
            _buildSpecItem("Net Weight", "${weight}kg"),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          "Description",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          product['description'] ?? "No description available.",
          style: TextStyle(color: Colors.grey[600], height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildReviewsTab(dynamic product) {
    final List<dynamic> reviews = product['reviews'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 30),
            const SizedBox(width: 8),
            const Text("4.5", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text("(${reviews.length} reviews)", style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: reviews.isEmpty 
            ? const Center(child: Text("No reviews yet. Be the first!"))
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                              child: Text(review['username']?[0] ?? '?', style: const TextStyle(fontSize: 10)),
                            ),
                            const SizedBox(width: 8),
                            Text(review['username'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            Row(
                              children: List.generate(5, (i) => Icon(
                                Icons.star, 
                                size: 12, 
                                color: i < review['rating'] ? Colors.amber : Colors.grey[300]
                              )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(review['comment'] ?? ""),
                      ],
                    ),
                  );
                },
              ),
        ),
        _buildReviewForm(),
      ],
    );
  }

  Widget _buildReviewForm() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          Row(
            children: [
              const Text("Rate: "),
              ...List.generate(5, (index) => IconButton(
                onPressed: () => setState(() => _selectedRating = index + 1),
                icon: Icon(Icons.star, color: _selectedRating > index ? Colors.amber : Colors.grey[300]),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _reviewController,
                  decoration: const InputDecoration(hintText: "Add your review...", border: InputBorder.none),
                ),
              ),
              IconButton(onPressed: _submitReview, icon: const Icon(Icons.send, color: AppTheme.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }
}
