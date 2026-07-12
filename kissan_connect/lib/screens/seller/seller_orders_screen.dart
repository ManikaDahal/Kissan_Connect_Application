import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kissan_connect/screens/chat/chat_screen.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/widgets/shimmer_loading.dart';

class SellerOrdersScreen extends StatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];
  // Track which item IDs are currently loading to prevent duplicate taps
  final Set<int> _updatingItems = {};

  @override
  void initState() {
    super.initState();
    _fetchSellerOrders();
  }

  Future<void> _fetchSellerOrders() async {
    try {
      final response = await ApiService.get('seller-orders/');
      if (mounted) {
        setState(() {
          _orders = response is List ? response : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: $e')),
        );
      }
    }
  }

  Future<void> _updateItemStatus(int itemId, String newStatus) async {
    if (_updatingItems.contains(itemId)) return;
    setState(() => _updatingItems.add(itemId));

    try {
      await ApiService.patch(
        'seller-orders/items/$itemId/status/',
        {'status': newStatus},
      );
      // Refresh full list to reflect the new state
      await _fetchSellerOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'delivered'
                  ? ' Marked as Delivered! Your payout has been released.'
                  : ' Marked as Shipped!',
            ),
            backgroundColor: newStatus == 'delivered' ? Colors.teal : Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingItems.remove(itemId));
    }
  }

  Color _orderStatusColor(String status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'shipped': return Colors.blue;
      case 'delivered': return Colors.teal;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color _itemStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'shipped': return Colors.blue;
      case 'delivered': return Colors.teal;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _itemStatusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.hourglass_top_rounded;
      case 'shipped': return Icons.local_shipping_outlined;
      case 'delivered': return Icons.done_all_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      default: return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Customer Orders',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchSellerOrders();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const SellerOrdersShimmer()
          : _orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchSellerOrders,
                  color: const Color(0xFF2E7D32),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_outlined, size: 64, color: Colors.green.shade300),
          ),
          const SizedBox(height: 20),
          const Text('No Orders Yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Text(
            'When buyers order your products,\nthey will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final orderStatus = order['status'] ?? 'pending';
    final statusColor = _orderStatusColor(orderStatus);
    final items = order['my_items'] as List? ?? [];
    final address = order['shipping_address'];
    final createdAt = DateTime.tryParse(order['created_at'] ?? '');
    final dateStr = createdAt != null
        ? DateFormat('MMM d, yyyy · h:mm a').format(createdAt.toLocal())
        : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Order ID + Order-level status badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text('Order #${order['id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    orderStatus.toUpperCase(),
                    style: TextStyle(
                        color: statusColor, fontSize: 11,
                        fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(dateStr,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ]),
                const SizedBox(height: 12),

                // Buyer info
                Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                    child: Text(
                      (order['buyer_name'] ?? 'B')[0].toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['buyer_name'] ?? 'Unknown Buyer',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(order['buyer_email'] ?? '',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ]),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // ── Per-item section with status controls ──
                Text('Your Items in This Order:',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700)),
                const SizedBox(height: 10),
                ...items.map((item) => _buildItemRow(item)),

                // Shipping address
                if (address != null) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Deliver To: ${address['full_name']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(
                              '${address['area']}, ${address['city']}, ${address['province']} Province',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            Text('Phone: ${address['phone_number']}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),

                // Total & payment gateway
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Via: ${order['payment_gateway']?.toUpperCase() ?? 'N/A'}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    Text(
                      'Rs. ${order['total_amount']}',
                      style: const TextStyle(

                        
                          fontSize: 16, fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final response = await ApiService.post('chat/conversations/get_or_create/', {
                          'user_id': order['buyer_id'] ?? 0,
                        });
                        if (response is Map && response['conversation_id'] != null) {
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: response['conversation_id'],
                                otherUserId: order['buyer_id'] ?? 0,
                                otherUserName: order['buyer_name'] ?? 'Buyer',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to start chat: $e')));
                        }
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat with buyer'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(dynamic item) {
    final itemId = item['item_id'] as int? ?? 0;
    final itemStatus = item['item_status'] as String? ?? 'pending';
    final isUpdating = _updatingItems.contains(itemId);
    final statusColor = _itemStatusColor(itemStatus);
    final statusIcon = _itemStatusIcon(itemStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item['quantity']}x ${item['product_name']}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Text('Rs. ${item['price']}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: statusColor)),
            ],
          ),
          const SizedBox(height: 8),

          // Status badge + action button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  itemStatus.toUpperCase(),
                  style: TextStyle(
                      color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),

              // Show action button only for actionable states
              if (itemStatus == 'pending')
                _actionButton(
                  label: 'Mark Shipped',
                  icon: Icons.local_shipping_outlined,
                  color: Colors.blue,
                  isLoading: isUpdating,
                  onTap: () => _updateItemStatus(itemId, 'shipped'),
                )
              else if (itemStatus == 'shipped')
                _actionButton(
                  label: 'Mark Delivered',
                  icon: Icons.done_all_rounded,
                  color: Colors.teal,
                  isLoading: isUpdating,
                  onTap: () => _updateItemStatus(itemId, 'delivered'),
                )
              else if (itemStatus == 'delivered')
                Row(children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.teal),
                  const SizedBox(width: 4),
                  Text('Payout Released',
                      style: TextStyle(
                          color: Colors.teal.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: isLoading
            ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}
