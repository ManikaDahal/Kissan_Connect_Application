import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kissan_connect/core/providers/cart_provider.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/theme/app_theme.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = false;
  String _selectedMethod = 'stripe';

  Future<void> _processPayment() async {
    final cart = ref.read(cartProvider);
    final total = ref.read(cartProvider.notifier).totalAmount;

    if (cart.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Create Order on Backend
      final orderData = await ApiService.post('orders/', {
        'items': cart.map((item) => {
          'product': item.product['id'],
          'quantity': item.quantity,
        }).toList(),
        'payment_gateway': _selectedMethod,
      });

      final int orderId = orderData['id'];

      if (_selectedMethod == 'stripe') {
        await _handleStripe(orderId);
      } else {
        await _handleKhalti(orderId, total);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleStripe(int orderId) async {
    // 1. Get Client Secret from Backend
    final response = await ApiService.post('orders/$orderId/create-stripe-payment-intent/', {});
    final clientSecret = response['clientSecret'];

    // 2. Initialize Payment Sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'KissanConnect',
        style: ThemeMode.light,
      ),
    );

    // 3. Present Payment Sheet
    await Stripe.instance.presentPaymentSheet();
    
    // 4. Success!
    _onPaymentSuccess();
  }

  Future<void> _handleKhalti(int orderId, double amount) async {
    try {
      // 1. Get Payment URL from Backend
      final Map<String, dynamic> response = await ApiService.post('orders/$orderId/initiate-khalti-payment/', {
        // Using a standard return_url format as fallback
        'return_url': 'https://kissan-connect-application.onrender.com/payment-success/', 
      });
      
      final String? paymentUrl = response['payment_url'] as String?;
      final String? pidx = response['pidx'] as String?;

      if (paymentUrl == null || pidx == null) {
        throw Exception("Backend did not return a payment URL. Response: $response");
      }

      // 2. Launch Browser
      final Uri uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // 3. Show Verification Dialog
        if (mounted) {
          _showKhaltiVerificationDialog(orderId, pidx);
        }
      } else {
        throw Exception("Could not launch URL: $paymentUrl. Please check your browser or AndroidManifest.xml.");
      }
    } catch (e) {
      if (mounted) {
        // Show more detailed error
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Khalti Error: $e"),
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  void _showKhaltiVerificationDialog(int orderId, String pidx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Completing Payment"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Please complete the payment in your browser and then click 'Verify'."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ApiService.post('orders/$orderId/verify-khalti-payment/', {
                  'pidx': pidx,
                });
                _onPaymentSuccess();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification Failed: $e")));
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text("Verify Payment"),
          ),
        ],
      ),
    );
  }

  void _onPaymentSuccess() {
    ref.read(cartProvider.notifier).clearCart();
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Success!"),
        content: const Text("Your payment was successful and your order is placed."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("Back to Home"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = ref.watch(cartProvider.notifier).totalAmount;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const CustomAppBar(title: "Checkout"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildPaymentOption('stripe', 'Stripe (Card)', Icons.credit_card),
                  _buildPaymentOption('khalti', 'Khalti', Icons.account_balance_wallet),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Payable"),
                            Text("Rs. ${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryGreen)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: total > 0 ? _processPayment : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Pay Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOption(String id, String label, IconData icon) {
    bool isSelected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryGreen : Colors.grey),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 16)),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }
}
