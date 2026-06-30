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
  late dynamic _currentProduct;
  List<dynamic> _similarProducts = [];
  bool _isLoadingSimilar = true;
  bool _isLoadingProduct = true;
  bool _isSubmittingReview = false;
  final TextEditingController _reviewController = TextEditingController();
  double _selectedRating = 5.0;

  @override
  void initState() {
    super.initState();
    _currentProduct = widget.product;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    _fetchProductDetails();
    _fetchSimilarProducts();
  }

  Future<void> _fetchProductDetails() async {
    try {
      final updatedProduct = await ApiService.get('products/products/${widget.product['id']}/');
      if (mounted) {
        setState(() {
          _currentProduct = updatedProduct;
          _isLoadingProduct = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingProduct = false);
    }
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
    if (_reviewController.text.isEmpty || _isSubmittingReview) return;
    
    setState(() => _isSubmittingReview = true);
    
    try {
      await ApiService.post('products/reviews/', {
        'product': _currentProduct['id'],
        'rating': _selectedRating,
        'comment': _reviewController.text,
      });
      
      // Fetch updated product to immediately show the new review and updated rating
      final updatedProduct = await ApiService.get('products/products/${_currentProduct['id']}/');
      
      if (mounted) {
        setState(() {
          _currentProduct = updatedProduct;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Review submitted successfully!")),
        );
        _reviewController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingReview = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _currentProduct;
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
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
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
                      // Toggle Tabs - Styled as solid segments
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          tabs: const [
                            Tab(text: "Details"),
                            Tab(text: "Reviews"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tab Content Area Adapts to Content Height
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _tabController.index == 0
                            ? _buildDetailsTab(product, weight, stock)
                            : _buildReviewsTab(product),
                      ),

                      // Similar Products - Only in Details Tab
                      if (_tabController.index == 0) ...[
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
                      ],
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
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        // Seller Information
        Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: const Icon(Icons.store, color: AppTheme.primaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sold By:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    product['shop_name'] ?? "Kissan Vendor",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product['shop_address'] ?? "Address not provided",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
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
    final double avgRating = (product['average_rating'] ?? 0.0).toDouble();
    final int totalReviews = product['total_reviews'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 30),
            const SizedBox(width: 8),
            Text(
              avgRating == 0 ? "No ratings" : avgRating.toStringAsFixed(1), 
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(width: 8),
            Text("($totalReviews reviews)", style: const TextStyle(color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingProduct)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: Text("No reviews yet. Be the first!")),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
        const SizedBox(height: 24),
        const Divider(),
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
              const SizedBox(width: 8),
              // Star Rating Logic: Single Tap (.5), Double Tap (1.0)
              ...List.generate(5, (index) {
                final int starIndex = index;
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = starIndex + 0.5),
                  onDoubleTap: () => setState(() => _selectedRating = starIndex + 1.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      starIndex < _selectedRating.floor() 
                          ? Icons.star 
                          : (starIndex < _selectedRating ? Icons.star_half : Icons.star_border),
                      color: starIndex < _selectedRating ? Colors.amber : Colors.grey[300],
                      size: 28,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 12),
              Text(_selectedRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _reviewController,
                  decoration: const InputDecoration(hintText: "Add your review...", border: InputBorder.none),
                  enabled: !_isSubmittingReview,
                ),
              ),
              _isSubmittingReview 
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(onPressed: _submitReview, icon: const Icon(Icons.send, color: AppTheme.primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }
}
