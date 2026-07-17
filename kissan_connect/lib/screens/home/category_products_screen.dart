import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_loading.dart';

class CategoryProductsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  bool _isSearchLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _sortBy;
  Timer? _debounce;
  int _currentPage = 1;
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;
  bool _isGridLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchProducts({bool isSearch = false, bool resetPage = false, bool isPaging = false}) async {
    if (resetPage || isSearch) {
      _currentPage = 1;
    }
    if (isSearch) {
      setState(() => _isSearchLoading = true);
    } else if (isPaging) {
      setState(() => _isGridLoading = true);
    } else if (_products.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    try {
      final data = await ApiService.get('products/products/', params: {
        'category': widget.categoryId.toString(),
        'page': _currentPage.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_sortBy != null) 'ordering': _sortBy!,
      });
      setState(() {
        if (data is Map) {
          _products = data['results'] ?? [];
          _hasNextPage = data['next'] != null;
          _hasPreviousPage = data['previous'] != null;
        } else {
          _products = data is List ? data : [];
          _hasNextPage = false;
          _hasPreviousPage = false;
        }
        _isLoading = false;
        _isSearchLoading = false;
        _isGridLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");
      setState(() {
        _isLoading = false;
        _isSearchLoading = false;
        _isGridLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(title: widget.categoryName),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
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
                controller: _searchController,
                onChanged: (v) {
                  _searchQuery = v;
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 500), () {
                    _fetchProducts(isSearch: true);
                  });
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: "Search in ${widget.categoryName}...",
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _fetchProducts(isSearch: true);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchQuery.isEmpty ? "All Products" : "Search Results",
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (_isSearchLoading)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.sort,
                        color: _sortBy != null ? AppTheme.primaryGreen : Colors.grey,
                      ),
                      onPressed: () => _showSortMenu(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading || _isGridLoading
                ? const CategoryGridShimmer()
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              "No products found",
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (context, index) {
                                return ProductCard(product: _products[index]);
                              },
                            ),
                          ),
                          if (_products.isNotEmpty && (_hasNextPage || _hasPreviousPage))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left, color: AppTheme.primaryGreen),
                                    onPressed: _hasPreviousPage
                                        ? () {
                                            setState(() {
                                              _currentPage--;
                                            });
                                            _fetchProducts(isPaging: true);
                                          }
                                        : null,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "Page $_currentPage",
                                      style: const TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right, color: AppTheme.primaryGreen),
                                    onPressed: _hasNextPage
                                        ? () {
                                            setState(() {
                                              _currentPage++;
                                            });
                                            _fetchProducts(isPaging: true);
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.sort, color: AppTheme.primaryGreen),
                    const SizedBox(width: 10),
                    Text("Sort By", style: AppTheme.lightTheme.textTheme.titleLarge),
                  ],
                ),
              ),
              _buildSortOption("Price: Low to High", "price"),
              _buildSortOption("Price: High to Low", "-price"),
              _buildSortOption("Newest First", "-created_at"),
              _buildSortOption("Name: A to Z", "name"),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String title, String value) {
    bool isSelected = _sortBy == value;
    return ListTile(
      title: Text(title, style: TextStyle(
        color: isSelected ? AppTheme.primaryGreen : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      )),
      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
      onTap: () {
        setState(() {
          _sortBy = isSelected ? null : value;
        });
        Navigator.pop(context);
        _fetchProducts(isSearch: true, resetPage: true);
      },
    );
  }
}
