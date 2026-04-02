import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissan_connect/core/providers/nav_provider.dart';
import 'package:kissan_connect/widgets/product_card.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';
import 'package:kissan_connect/widgets/weather_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _famousProducts = [];
  List<dynamic> _allProducts = [];
  bool _isLoading = true;
  bool _isSearchLoading = false;
  String _searchQuery = '';
  int? _selectedCategory;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool isSearch = false}) async {
    if (isSearch) {
      setState(() => _isSearchLoading = true);
    } else {
      setState(() => _isLoading = true);
    }
    try {
      final categoriesData = await ApiService.get('products/categories/');
      final productsData = await ApiService.get('products/products/', params: {
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedCategory != null) 'category': _selectedCategory.toString(),
      });
      
      final famousData = await ApiService.get('products/products/', params: {'is_famous': 'true'});

      setState(() {
        _categories = (categoriesData is Map && categoriesData.containsKey('results')) ? categoriesData['results'] : categoriesData;
        _allProducts = (productsData is Map && productsData.containsKey('results')) ? productsData['results'] : productsData;
        _famousProducts = (famousData is Map && famousData.containsKey('results')) ? famousData['results'] : famousData;
        _isLoading = false;
        _isSearchLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        _isLoading = false;
        _isSearchLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: "KissanConnect",
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (v) {
                        _searchQuery = v;
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          _fetchData(isSearch: true);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search fresh products...",
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Weather Suggestion
                  const WeatherCard(),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Categories", style: AppTheme.lightTheme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () {
                          ref.read(navProvider.notifier).state = 1;
                        },
                        child: const Text("See All", style: TextStyle(color: AppTheme.primaryGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildCategoryItem("All", null);
                        }
                        final cat = _categories[index - 1];
                        return _buildCategoryItem(cat['name'], cat['id'], imageUrl: cat['image']);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Famous Products
                  if (_famousProducts.isNotEmpty) ...[
                    Text("Featured Products", style: AppTheme.lightTheme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _famousProducts.length,
                        itemBuilder: (context, index) {
                          final product = _famousProducts[index];
                          return ProductCard(product: product, horizontal: true);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // All Products
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("All Products", style: AppTheme.lightTheme.textTheme.titleLarge),
                      if (_isSearchLoading)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _allProducts.length,
                    itemBuilder: (context, index) {
                      final product = _allProducts[index];
                      return ProductCard(product: product);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCategoryItem(String name, int? id, {String? imageUrl}) {
    bool isSelected = _selectedCategory == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = id);
        _fetchData();
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGreen : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Icon(
                        id == null ? Icons.apps : Icons.category,
                        color: isSelected ? Colors.white : AppTheme.primaryGreen,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryGreen : Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
