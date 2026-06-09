import 'package:flutter/material.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';
import 'add_product_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  bool _isLoading = true;
  List<dynamic> _myProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchMyProducts();
  }

  Future<void> _fetchMyProducts() async {
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

  Future<void> _updateStock(int productId, int currentStock) async {
    final controller = TextEditingController(text: currentStock.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Stock"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "New Stock Quantity"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.patch('products/seller/my-items/$productId/update-stock/', {
                  'stock': int.parse(controller.text)
                });
                Navigator.pop(context);
                _fetchMyProducts();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stock updated!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Seller Hub"),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchMyProducts,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(),
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
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _statCard("Active Products", _myProducts.length.toString(), Icons.inventory_2, Colors.blue),
        _statCard("Total Sales", "Rs. 0", Icons.payments_outlined, Colors.orange),
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
        trailing: IconButton(
          icon: const Icon(Icons.edit_calendar_outlined, color: Colors.blue),
          onPressed: () => _updateStock(product['id'], product['stock'] ?? 0),
          tooltip: "Update Stock",
        ),
      ),
    );
  }
}
