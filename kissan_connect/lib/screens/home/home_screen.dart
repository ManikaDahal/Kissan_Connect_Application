import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kissan_connect/core/providers/nav_provider.dart';
import 'package:kissan_connect/widgets/product_card.dart';
import 'package:kissan_connect/widgets/shimmer_loading.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';
import 'package:kissan_connect/widgets/weather_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  List<dynamic> _categories = [];
  List<dynamic> _famousProducts = [];
  List<dynamic> _allProducts = [];
  bool _isLoading = true;
  bool _isSearchLoading = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategory;
  String? _sortBy;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initData();
  }

  /// Loads cache first, then decides whether to show shimmer or do a silent refresh.
  Future<void> _initData() async {
    await _loadCachedData();
    // If cache gave us products, do a quiet background refresh (no shimmer).
    // If cache was empty, do a normal fetch so _isLoading=true triggers the shimmer.
    if (_allProducts.isNotEmpty) {
      _fetchData(isSilent: true);
    } else {
      _fetchData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh silently when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _fetchData(isRefresh: true);
    }
  }

  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedCats = prefs.getString('cache_categories');
      final cachedFam = prefs.getString('cache_famous_products');
      final cachedAll = prefs.getString('cache_all_products');

      if (mounted) {
        setState(() {
          if (cachedCats != null) _categories = jsonDecode(cachedCats);
          if (cachedFam != null) _famousProducts = jsonDecode(cachedFam);
          if (cachedAll != null) _allProducts = jsonDecode(cachedAll);
          
          // If we have cached products, we can hide the full-screen loader immediately
          if (_allProducts.isNotEmpty) {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading cache: $e");
    }
  }

  Future<void> _saveDataToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cache_categories', jsonEncode(_categories));
      await prefs.setString('cache_famous_products', jsonEncode(_famousProducts));
      await prefs.setString('cache_all_products', jsonEncode(_allProducts));
    } catch (e) {
      debugPrint("Error saving cache: $e");
    }
  }

  Future<void> _fetchData({bool isSearch = false, bool isRefresh = false, bool isSilent = false}) async {
    if (isSearch) {
      setState(() => _isSearchLoading = true);
    } else if (!isRefresh && !isSilent && _allProducts.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    try {
      // Prepare futures for parallel execution
      final List<Future<dynamic>> futures = [];
      
      // 0: Categories (conditional)
      if (_categories.isEmpty || isRefresh || isSilent) {
        futures.add(ApiService.get('products/categories/').catchError((e) {
          debugPrint("Categories error: $e");
          return null;
        }));
      } else {
        futures.add(Future.value(null));
      }
      
      // 1: Products (always)
      futures.add(ApiService.get('products/products/', params: {
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedCategory != null) 'category': _selectedCategory.toString(),
        if (_sortBy != null) 'ordering': _sortBy!,
      }).catchError((e) {
        debugPrint("Products error: $e");
        return null;
      }));
      
      // 2: Famous products (conditional)
      if (_searchQuery.isEmpty && (_famousProducts.isEmpty || isRefresh || isSilent)) {
        futures.add(ApiService.get('products/products/', params: {'is_famous': 'true'}).catchError((e) {
          debugPrint("Famous products error: $e");
          return null;
        }));
      } else {
        futures.add(Future.value(null));
      }

      // Execute all calls in parallel
      final results = await Future.wait(futures);
      final categoriesData = results[0];
      final productsData = results[1];
      final famousData = results[2];

      if (mounted) {
        setState(() {
          if (categoriesData != null) {
            _categories = (categoriesData is Map && categoriesData.containsKey('results')) 
                ? categoriesData['results'] 
                : categoriesData;
          }
          
          if (productsData != null) {
            _allProducts = (productsData is Map && productsData.containsKey('results')) 
                ? productsData['results'] 
                : productsData;
          }
          
          if (famousData != null) {
            _famousProducts = (famousData is Map && famousData.containsKey('results')) 
                ? famousData['results'] 
                : famousData;
          }
          
          _isLoading = false;
          _isSearchLoading = false;
        });

        // Trigger cache save in the background
        _saveDataToCache();
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSearchLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(navProvider, (previous, next) {
      if (next == 0) {
        _fetchData(isSilent: true);
      }
    });

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
        ? const HomeScreenShimmer()
        : RefreshIndicator(
            onRefresh: () => _fetchData(isRefresh: true),
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
                      controller: _searchController,
                      onChanged: (v) {
                        _searchQuery = v;
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          _fetchData(isSearch: true);
                        });
                        setState(() {}); // For clear icon visibility
                      },
                      decoration: InputDecoration(
                        hintText: "Search fresh products...",
                        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                        suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                                _fetchData(isSearch: true);
                              },
                            )
                          : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (_searchQuery.isEmpty) ...[
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
                            return ProductCard(
                              product: product,
                              horizontal: true,
                              onPop: () => _fetchData(isSilent: true),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],

                  // All Products / Search Results
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchQuery.isEmpty ? "All Products" : "Search Results", 
                        style: AppTheme.lightTheme.textTheme.titleLarge
                      ),
                      Row(
                        children: [
                          if (_isSearchLoading)
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.sort, 
                              color: _sortBy != null ? AppTheme.primaryGreen : Colors.grey
                            ),
                            onPressed: () => _showSortMenu(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_allProducts.isEmpty && !_isSearchLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              "No products found",
                               style: TextStyle(color: Colors.grey[600], fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
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
                        return ProductCard(
                          product: product,
                          onPop: () => _fetchData(isSilent: true),
                        );
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
        _fetchData(isSearch: true);
      },
    );
  }
}
