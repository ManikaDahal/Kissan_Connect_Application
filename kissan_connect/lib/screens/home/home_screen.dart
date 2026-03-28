import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _categories = [];
  List<dynamic> _famousProducts = [];
  List<dynamic> _allProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final categoriesData = await ApiService.get('products/categories/');
      final productsData = await ApiService.get('products/products/', params: {
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        if (_selectedCategory != null) 'category': _selectedCategory.toString(),
      });
      
      final famousData = await ApiService.get('products/products/', params: {'is_famous': 'true'});

      setState(() {
        _categories = categoriesData['results'] ?? categoriesData;
        _allProducts = productsData['results'] ?? productsData;
        _famousProducts = famousData['results'] ?? famousData;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KissanConnect"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    onChanged: (v) {
                      _searchQuery = v;
                      _fetchData();
                    },
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Categories
                  Text("Categories", style: AppTheme.lightTheme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: const Text("All"),
                              selected: _selectedCategory == null,
                              onSelected: (v) {
                                setState(() => _selectedCategory = null);
                                _fetchData();
                              },
                            ),
                          );
                        }
                        final cat = _categories[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cat['name']),
                            selected: _selectedCategory == cat['id'],
                            onSelected: (v) {
                              setState(() => _selectedCategory = cat['id']);
                              _fetchData();
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Famous Products
                  if (_famousProducts.isNotEmpty) ...[
                    Text("Famous Products", style: AppTheme.lightTheme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _famousProducts.length,
                        itemBuilder: (context, index) {
                          final product = _famousProducts[index];
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 16),
                            child: Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                      ),
                                      child: const Center(child: Icon(Icons.image, color: Colors.white)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                                        Text("${product['price']}", style: const TextStyle(color: AppTheme.primaryGreen)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // All Products
                  Text("All Products", style: AppTheme.lightTheme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _allProducts.length,
                    itemBuilder: (context, index) {
                      final product = _allProducts[index];
                      return Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Container(color: Colors.grey[200], child: const Center(child: Icon(Icons.shopping_bag)))),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text("${product['price']}", style: const TextStyle(color: AppTheme.primaryGreen)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
