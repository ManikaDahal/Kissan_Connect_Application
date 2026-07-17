import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kissan_connect/core/providers/nav_provider.dart';
import 'package:kissan_connect/screens/home/categories_screen.dart';
import 'package:kissan_connect/widgets/product_card.dart';
import 'package:kissan_connect/widgets/shimmer_loading.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';
import 'package:kissan_connect/widgets/weather_card.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  List<dynamic> _categories = [];
  List<dynamic> _famousProducts = [];
  List<dynamic> _allProducts = [];
  List<dynamic> _nearbyProducts = [];
  List<dynamic> _recommendedProducts = [];
  bool _isLoading = true;
  bool _isSearchLoading = false;
  bool _isLoadingNearby = false;
  bool _isLoadingRecommendations = false;
  String? _locationMessage;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _selectedCategory;
  String? _sortBy;
  Timer? _debounce;
  int _allProductsPage = 1;
  bool _hasNextAllProducts = false;
  bool _hasPreviousAllProducts = false;
  int _unreadNotificationCount = 0;
  final Map<int, Map<String, dynamic>> _pageCache = {};
  bool _isPrefetching = false;
  bool _isGridLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initData();
  }

  Future<void> _fetchUnreadNotificationCount() async {
    try {
      final response = await ApiService.get('notifications/unread-count/');
      if (response != null && response is Map<String, dynamic>) {
        if (mounted) {
          setState(() {
            _unreadNotificationCount = response['unread_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching unread count: $e");
    }
  }

  /// Loads cache first, then decides whether to show shimmer or do a silent refresh.
  Future<void> _initData() async {
    await _loadCachedData();
    _fetchUnreadNotificationCount();
    if (_allProducts.isNotEmpty) {
      await _fetchData(isSilent: true);
    } else {
      await _fetchData();
    }
    await Future.wait([_fetchNearbyProducts(), _fetchRecommendations()]);
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

  Future<void> _fetchNearbyProducts() async {
    if (!mounted) return;
    setState(() => _isLoadingNearby = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationMessage = 'Enable location to see nearby products.';
            _nearbyProducts = [];
            _isLoadingNearby = false;
          });
        }
        return;
      }

      // Try last known position first for speed
      Position? position = await Geolocator.getLastKnownPosition();
      
      // If none, get current with low accuracy and short timeout
      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );

      final data = await ApiService.get('products/products/nearby/', params: {
        'lat': position.latitude.toString(),
        'lon': position.longitude.toString(),
        'limit': '6',
      });

      final List<dynamic> productsList = (data is Map && data.containsKey('results'))
          ? List<dynamic>.from(data['results'])
          : (data is List ? List<dynamic>.from(data) : []);

      if (mounted) {
        setState(() {
          _nearbyProducts = productsList;
          _locationMessage = null;
          _isLoadingNearby = false;
        });
      }
    } catch (e) {
      debugPrint('Nearby products error: $e');
      if (mounted) {
        setState(() {
          _locationMessage = 'Unable to load nearby products right now.';
          _nearbyProducts = [];
          _isLoadingNearby = false;
        });
      }
    }
  }

  Future<void> _fetchRecommendations() async {
    if (_allProducts.isEmpty) return;
    setState(() => _isLoadingRecommendations = true);

    try {
      final productId = _allProducts.first['id'];
      if (productId == null) {
        if (mounted) setState(() => _isLoadingRecommendations = false);
        return;
      }

      final data = await ApiService.get('products/products/recommendations/', params: {
        'product_id': productId.toString(),
        'limit': '6',
      });

      final List<dynamic> productsList = (data is Map && data.containsKey('results'))
          ? List<dynamic>.from(data['results'])
          : (data is List ? List<dynamic>.from(data) : []);

      if (mounted) {
        setState(() {
          _recommendedProducts = productsList;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      debugPrint('Recommendations error: $e');
      if (mounted) {
        setState(() {
          _recommendedProducts = [];
          _isLoadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _fetchData({
    bool isSearch = false,
    bool isRefresh = false,
    bool isSilent = false,
    bool resetPage = false,
    bool isPaging = false,
  }) async {
    if (resetPage || isSearch || isRefresh) {
      _allProductsPage = 1;
      _pageCache.clear();
    }
    
    // Check cache for paging
    if (isPaging && _pageCache.containsKey(_allProductsPage)) {
      final cached = _pageCache[_allProductsPage]!;
      setState(() {
        _allProducts = cached['results'] ?? [];
        _hasNextAllProducts = cached['next'] ?? false;
        _hasPreviousAllProducts = cached['previous'] ?? false;
        _isSearchLoading = false;
        _isLoading = false;
        _isGridLoading = false;
      });
      if (_hasNextAllProducts && !isSearch) {
        _prefetchNextPage();
      }
      return;
    } else if (isPaging) {
      setState(() => _isGridLoading = true);
    }

    if (isSearch) {
      setState(() => _isSearchLoading = true);
    } else if (!isRefresh && !isSilent && _allProducts.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    try {
      // 1. Fetch Categories separately (only if needed)
      if (!isPaging && (_categories.isEmpty || isRefresh || isSilent)) {
        ApiService.get('products/categories/').then((data) {
          if (mounted && data != null) {
            setState(() {
              _categories = (data is Map && data.containsKey('results')) ? data['results'] : data;
            });
            _saveDataToCache();
          }
        }).catchError((e) => debugPrint("Categories error: $e"));
      }
      
      // 2. Fetch Famous products separately
      if (!isPaging && _searchQuery.isEmpty && (_famousProducts.isEmpty || isRefresh || isSilent)) {
        ApiService.get('products/products/', params: {'is_famous': 'true'}).then((data) {
          if (mounted && data != null) {
            setState(() {
              _famousProducts = (data is Map && data.containsKey('results')) ? data['results'] : data;
            });
            _saveDataToCache();
          }
        }).catchError((e) => debugPrint("Famous products error: $e"));
      }

      // 3. Fetch Unread notifications count separately
      if (!isPaging) {
        ApiService.get('notifications/unread-count/').then((data) {
          if (mounted && data != null && data is Map && data.containsKey('unread_count')) {
            setState(() {
              _unreadNotificationCount = data['unread_count'] ?? 0;
            });
          }
        }).catchError((e) => debugPrint("Unread notifications error: $e"));
      }
 
      // 4. Main Products Fetch (The only one we await to show main content)
      final productsData = await ApiService.get('products/products/', params: {
        'page': _allProductsPage.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedCategory != null) 'category': _selectedCategory.toString(),
        if (_sortBy != null) 'ordering': _sortBy!,
      });
 
      if (mounted) {
        setState(() {
          if (productsData != null) {
            if (productsData is Map) {
              _allProducts = productsData['results'] ?? [];
              _hasNextAllProducts = productsData['next'] != null;
              _hasPreviousAllProducts = productsData['previous'] != null;
              _pageCache[_allProductsPage] = {
                'results': _allProducts,
                'next': _hasNextAllProducts,
                'previous': _hasPreviousAllProducts,
              };
            } else {
              _allProducts = productsData is List ? productsData : [];
              _hasNextAllProducts = false;
              _hasPreviousAllProducts = false;
              _pageCache[_allProductsPage] = {
                'results': _allProducts,
                'next': false,
                'previous': false,
              };
            }
          }
          _isLoading = false;
          _isSearchLoading = false;
          _isGridLoading = false;
        });

        _saveDataToCache();
        if (!isSearch && !isPaging) {
          unawaited(_fetchNearbyProducts());
          unawaited(_fetchRecommendations());
        }
        
        if (_hasNextAllProducts && !isSearch) {
          _prefetchNextPage();
        }
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSearchLoading = false;
          _isGridLoading = false;
        });
      }
    }
  }

  Future<void> _prefetchNextPage() async {
    if (_isPrefetching) return;
    final nextPage = _allProductsPage + 1;
    if (_pageCache.containsKey(nextPage)) return;

    _isPrefetching = true;
    try {
      final productsData = await ApiService.get('products/products/', params: {
        'page': nextPage.toString(),
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedCategory != null) 'category': _selectedCategory.toString(),
        if (_sortBy != null) 'ordering': _sortBy!,
      });
      
      if (productsData != null) {
        List<dynamic> items = [];
        bool hasNext = false;
        bool hasPrevious = false;
        if (productsData is Map) {
          items = productsData['results'] ?? [];
          hasNext = productsData['next'] != null;
          hasPrevious = productsData['previous'] != null;
        } else if (productsData is List) {
          items = productsData;
        }
        _pageCache[nextPage] = {
          'results': items,
          'next': hasNext,
          'previous': hasPrevious,
        };
      }
    } catch (e) {
      debugPrint("Prefetch error: $e");
    } finally {
      _isPrefetching = false;
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () async {
                  await RouteGenerator.navigateToPage(context, Routes.notificationsRoute);
                  _fetchUnreadNotificationCount();
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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
                      readOnly: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                      decoration: const InputDecoration(
                        hintText: "Search fresh products...",
                        prefixIcon: Icon(Icons.search, color: AppTheme.primaryGreen),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                            );
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
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          return _buildCategoryItem(cat['name'], cat['id'], imageUrl: cat['image']);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_nearbyProducts.isNotEmpty || _isLoadingNearby || _locationMessage != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Nearby Products", style: AppTheme.lightTheme.textTheme.titleLarge),
                          Text("Based on your location", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingNearby)
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (_, __) => const HorizontalProductCardShimmer(),
                          ),
                        )
                      else if (_nearbyProducts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(_locationMessage ?? 'No nearby products available yet.'),
                        )
                      else
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _nearbyProducts.length,
                            itemBuilder: (context, index) {
                              final product = _nearbyProducts[index];
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

                    if (_recommendedProducts.isNotEmpty || _isLoadingRecommendations) ...[
                      Text("Recommended For You", style: AppTheme.lightTheme.textTheme.titleLarge),
                      const SizedBox(height: 12),
                      if (_isLoadingRecommendations)
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 3,
                            itemBuilder: (_, __) => const HorizontalProductCardShimmer(),
                          ),
                        )
                      else
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recommendedProducts.length,
                            itemBuilder: (context, index) {
                              final product = _recommendedProducts[index];
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
                  if (_allProducts.isEmpty && !_isSearchLoading && !_isGridLoading)
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
                  else if (_isGridLoading)
                    const ProductGridShimmer(itemCount: 4)
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
                  if (_allProducts.isNotEmpty && (_hasNextAllProducts || _hasPreviousAllProducts))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: AppTheme.primaryGreen),
                            onPressed: _hasPreviousAllProducts
                                ? () {
                                    setState(() {
                                      _allProductsPage--;
                                    });
                                    _fetchData(isSilent: true, isPaging: true);
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
                              "Page $_allProductsPage",
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: AppTheme.primaryGreen),
                            onPressed: _hasNextAllProducts
                                ? () {
                                    setState(() {
                                      _allProductsPage++;
                                    });
                                    _fetchData(isSilent: true, isPaging: true);
                                  }
                                : null,
                          ),
                        ],
                      ),
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
        setState(() => _selectedCategory = (_selectedCategory == id ? null : id));
        _fetchData(resetPage: true);
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
                    ? Image.network(ApiService.getImageUrl(imageUrl), fit: BoxFit.cover)
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
