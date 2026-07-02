import 'package:flutter/material.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';

class SellerEarningsScreen extends StatefulWidget {
  const SellerEarningsScreen({super.key});

  @override
  State<SellerEarningsScreen> createState() => _SellerEarningsScreenState();
}

class _SellerEarningsScreenState extends State<SellerEarningsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.get('seller-orders/earnings/');
      setState(() {
        _data = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'My Earnings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _fetchEarnings, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchEarnings,
                  color: const Color(0xFF2E7D32),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        _buildTransactionHistory(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    final totalEarned = _data?['total_earned'] ?? 0.0;
    final pendingClearance = _data?['pending_clearance'] ?? 0.0;
    final releasedWaiting = _data?['released_waiting'] ?? 0.0;
    final totalBalance = pendingClearance + releasedWaiting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero total balance card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.white70, size: 18),
                  SizedBox(width: 6),
                  Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Rs. ${totalBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pending clearance + Awaiting transfer',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Three stat cards in a row
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                label: 'Total Earned',
                value: 'Rs. ${(totalEarned as double).toStringAsFixed(2)}',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF2E7D32),
                subtitle: 'Paid out to you',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                label: 'On Hold',
                value: 'Rs. ${(pendingClearance as double).toStringAsFixed(2)}',
                icon: Icons.hourglass_empty_rounded,
                color: const Color(0xFFE65100),
                subtitle: 'Awaiting delivery',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                label: 'Released',
                value: 'Rs. ${(releasedWaiting as double).toStringAsFixed(2)}',
                icon: Icons.send_outlined,
                color: const Color(0xFF1565C0),
                subtitle: 'Awaiting transfer',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    final transactions = _data?['transactions'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction History',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text('No transactions yet', style: TextStyle(color: Colors.grey, fontSize: 15)),
                SizedBox(height: 4),
                Text(
                  'Transactions appear after a customer pays for your products.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) => _buildTransactionCard(transactions[index]),
          ),
      ],
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    final status = tx['status'] as String;
    final netPayout = tx['net_payout'] as double;
    final grossAmount = tx['gross_amount'] as double;
    final commission = tx['commission_amount'] as double;
    final orderId = tx['order_id'];
    final createdAt = DateTime.tryParse(tx['created_at'] ?? '');

    final statusConfig = _statusConfig(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusConfig['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusConfig['icon'], color: statusConfig['color'], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$orderId',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (createdAt != null)
                      Text(
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rs. ${netPayout.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: statusConfig['color'],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusConfig['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusConfig['label'],
                      style: TextStyle(color: statusConfig['color'], fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _txDetail('Sale Amount', 'Rs. ${grossAmount.toStringAsFixed(2)}', Colors.black87),
              _txDetail('Platform Fee (5%)', '- Rs. ${commission.toStringAsFixed(2)}', Colors.red[400]!),
              _txDetail('Your Payout', 'Rs. ${netPayout.toStringAsFixed(2)}', const Color(0xFF2E7D32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _txDetail(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case 'held':
        return {'color': const Color(0xFFE65100), 'icon': Icons.hourglass_empty, 'label': 'On Hold'};
      case 'released':
        return {'color': const Color(0xFF1565C0), 'icon': Icons.send, 'label': 'Released'};
      case 'paid_out':
        return {'color': const Color(0xFF2E7D32), 'icon': Icons.check_circle, 'label': 'Paid Out'};
      case 'refunded':
        return {'color': Colors.red, 'icon': Icons.undo, 'label': 'Refunded'};
      default:
        return {'color': Colors.grey, 'icon': Icons.help_outline, 'label': status};
    }
  }
}
