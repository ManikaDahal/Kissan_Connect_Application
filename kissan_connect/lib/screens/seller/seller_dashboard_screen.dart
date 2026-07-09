import 'package:flutter/material.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';
import 'add_product_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_earnings_screen.dart';
import 'package:kissan_connect/widgets/shimmer_loading.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _myProducts = [];
  double _totalBalance = 0.0;
  double _pendingClearance = 0.0;
  double _totalEarned = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchMyProducts();
    _fetchEarningsSummary();
  }

  Future<void> _fetchMyProducts({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('products/seller/my-items/');
      if (mounted) {
        setState(() {
          _myProducts = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching products: $e")),
        );
      }
    }
  }

  Future<void> _deleteProduct(int productId, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Product", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "$productName"? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.delete('products/seller/my-items/$productId/');
      if (mounted) {
        setState(() {
          _myProducts.removeWhere((p) => p['id'] == productId);
        });
        _fetchMyProducts(silent: true);
        _fetchEarningsSummary();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product deleted."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _fetchEarningsSummary() async {
    try {
      final response = await ApiService.get('seller-orders/earnings/');
      if (mounted) {
        setState(() {
          _totalEarned = (response['total_earned'] as num).toDouble();
          _pendingClearance = (response['pending_clearance'] as num).toDouble();
          final released = (response['released_waiting'] as num).toDouble();
          _totalBalance = _pendingClearance + released;
        });
      }
    } catch (_) {}
  }

  Future<void> _editProduct(int productId, double currentPrice, int currentStock) async {
    final priceController = TextEditingController(text: currentPrice.toString());
    final stockController = TextEditingController(text: currentStock.toString());
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Price & Stock", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Price (Rs.)",
                  border: OutlineInputBorder(),
                  prefixText: "Rs. ",
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  if (double.tryParse(v) == null) return "Enter a valid price";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stock Quantity",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Required";
                  if (int.tryParse(v) == null) return "Enter a valid number";
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final newStock = int.parse(stockController.text);
                final newPrice = double.parse(priceController.text);
                // Update stock
                await ApiService.patch('products/seller/my-items/$productId/update-stock/', {
                  'stock': newStock
                });
                // Update price
                await ApiService.patch('products/seller/my-items/$productId/update-price/', {
                  'price': newPrice
                });
                if (mounted) {
                  setState(() {
                    final index = _myProducts.indexWhere((p) => p['id'] == productId);
                    if (index != -1) {
                      final updatedProduct = Map<String, dynamic>.from(_myProducts[index]);
                      updatedProduct['stock'] = newStock;
                      updatedProduct['price'] = newPrice.toString();
                      _myProducts[index] = updatedProduct;
                    }
                  });
                  Navigator.pop(context);
                  _fetchMyProducts(silent: true);
                  _fetchEarningsSummary();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product updated successfully!")));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
      
        title: "Seller Hub"),
      body: _isLoading 
        ? const SellerDashboardShimmer()
        : RefreshIndicator(
            onRefresh: _fetchMyProducts,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 16),
                  // View Customer Orders Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SellerOrdersScreen()),
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, color: Color(0xFF2E7D32)),
                      label: const Text(
                        'View Customer Orders',
                        style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("My Inventory", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddProductScreen()),
                          );
                          if (result == true) {
                            _fetchMyProducts();
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add New"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _myProducts.isEmpty 
                    ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No products yet. Start selling!")))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myProducts.length,
                        itemBuilder: (context, index) {
                          final product = _myProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildStatCards() {
    return Column(
      children: [
        // Earnings preview banner — tap to open full screen
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SellerEarningsScreen()),
          ).then((_) => _fetchEarningsSummary()),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        'Rs. ${_totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total earned: Rs. ${_totalEarned.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('View Details', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Existing product stats
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _statCard("Active Products", _myProducts.length.toString(), Icons.inventory_2, Colors.blue),
            _statCard("Total Stock", _myProducts.fold<int>(0, (sum, p) => sum + ((p['stock'] ?? 0) as int)).toString(), Icons.warehouse_outlined, Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product['image'] ?? 'https://via.placeholder.com/150',
            width: 60, height: 60, fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey, width: 60, height: 60, child: const Icon(Icons.image_not_supported)),
          ),
        ),
        title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Price: Rs. ${product['price']}"),
            Text("Store: ${product['shop_name'] ?? 'Your Shop'}", style: const TextStyle(color: Colors.blue, fontSize: 12)),
            const SizedBox(height: 4),
            Text("Stock: ${product['stock']} units", style: TextStyle(color: (product['stock'] ?? 0) < 5 ? Colors.red : Colors.green)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () {
                final price = double.tryParse(product['price'].toString()) ?? 0.0;
                final stock = (product['stock'] ?? 0) as int;
                _editProduct(product['id'], price, stock);
              },
              tooltip: "Edit Price & Stock",
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteProduct(product['id'], product['name']),
              tooltip: "Delete Product",
            ),
          ],
        ),
      ),
    );
  }
}
