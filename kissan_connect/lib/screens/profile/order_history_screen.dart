import 'package:flutter/material.dart';
import 'package:kissan_connect/core/models/order_model.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:kissan_connect/widgets/shimmer_loading.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<OrderModel> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get('orders/');
      List<dynamic> listContent = [];
      if (response is List) {
        listContent = response;
      } else if (response is Map && response.containsKey('results')) {
        listContent = response['results'];
      }
      setState(() {
        orders = listContent.map((o) => OrderModel.fromJson(o)).toList();
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My Orders", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: isLoading
          ? const OrderListShimmer()
          : orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  color: const Color(0xFF2E7D32),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) => _buildOrderCard(orders[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("You haven't placed any orders yet",
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            child: const Text("Start Shopping", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final dateStr = DateFormat('MMM d, yyyy').format(order.createdAt);
    final orderStatusConfig = _orderStatusConfig(order.status);

    // Determine overall delivery progress from items
    final allDelivered = order.items.isNotEmpty &&
        order.items.every((i) => i.status == 'delivered');
    final anyShipped = order.items.any((i) => i.status == 'shipped' || i.status == 'delivered');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Order #${order.id}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text("$dateStr  •  Rs. ${order.totalAmount.toStringAsFixed(2)}",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              _statusBadge(
                orderStatusConfig['label'],
                orderStatusConfig['color'],
              ),
            ],
          ),
          // Show delivery progress bar only for paid orders
          subtitle: order.status == 'paid'
              ? Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: _buildDeliveryProgressBar(anyShipped, allDelivered),
                )
              : null,
          children: [
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 10),
            ...order.items.map((item) => _buildItemRow(item)),
            const Divider(height: 24),
            if (order.shippingAddress != null) ...[
              _infoRow(Icons.location_on_outlined, "Shipping Address",
                  "${order.shippingAddress!.fullName}\n${order.shippingAddress!.summary}"),
              const SizedBox(height: 10),
            ],
            _infoRow(
              Icons.payment_outlined,
              "Payment Method",
              order.paymentGateway.toUpperCase(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryProgressBar(bool anyShipped, bool allDelivered) {
    final steps = ['Confirmed', 'Shipped', 'Delivered'];
    int activeStep = 0;
    if (anyShipped) activeStep = 1;
    if (allDelivered) activeStep = 2;

    return Row(
      children: List.generate(steps.length, (index) {
        final isDone = index <= activeStep;
        final isLast = index == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isDone ? const Color(0xFF2E7D32) : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(steps[index],
                      style: TextStyle(
                        fontSize: 9,
                        color: isDone ? const Color(0xFF2E7D32) : Colors.grey,
                        fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                      )),
                ],
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: index < activeStep ? const Color(0xFF2E7D32) : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildItemRow(OrderItemModel item) {
    final itemConfig = _itemStatusConfig(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (itemConfig['color'] as Color).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (itemConfig['color'] as Color).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(itemConfig['icon'] as IconData, color: itemConfig['color'] as Color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${item.quantity}x ${item.productName}",
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text("Rs. ${(item.price * item.quantity).toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          _statusBadge(itemConfig['label'] as String, itemConfig['color'] as Color),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _orderStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return {'label': 'PAID', 'color': const Color(0xFF2E7D32)};
      case 'pending':
        return {'label': 'PENDING', 'color': Colors.orange};
      case 'failed':
        return {'label': 'FAILED', 'color': Colors.red};
      case 'cancelled':
        return {'label': 'CANCELLED', 'color': Colors.red};
      default:
        return {'label': status.toUpperCase(), 'color': Colors.blue};
    }
  }

  Map<String, dynamic> _itemStatusConfig(String status) {
    switch (status) {
      case 'shipped':
        return {'label': 'Shipped', 'color': const Color(0xFF1565C0), 'icon': Icons.local_shipping};
      case 'delivered':
        return {'label': 'Delivered', 'color': const Color(0xFF2E7D32), 'icon': Icons.check_circle};
      case 'cancelled':
        return {'label': 'Cancelled', 'color': Colors.red, 'icon': Icons.cancel_outlined};
      default:
        return {'label': 'Processing', 'color': Colors.orange, 'icon': Icons.hourglass_empty};
    }
  }
}
