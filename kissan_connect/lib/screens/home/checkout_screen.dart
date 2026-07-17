import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kissan_connect/core/providers/cart_provider.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/theme/app_theme.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';
import 'package:kissan_connect/core/models/address_model.dart';
import 'package:kissan_connect/screens/profile/add_address_screen.dart';
import 'package:kissan_connect/core/utils/error_helper.dart';
import 'package:kissan_connect/core/utils/const.dart';
import 'package:kissan_connect/widgets/blur_loading_overlay.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = false;
  String _selectedMethod = 'stripe';
  UserAddress? _selectedAddress;
  List<UserAddress> _allAddresses = [];

  @override
  void initState() {
    super.initState();
    _fetchDefaultAddress();
  }

  Future<void> _fetchDefaultAddress() async {
    try {
      final response = await ApiService.get('users/addresses/');
      List<dynamic> listContent = [];

      if (response is List) {
        listContent = response;
      } else if (response is Map && response.containsKey('results')) {
        listContent = response['results'];
      }

      if (listContent.isNotEmpty) {
        setState(() {
          _allAddresses = listContent.map((a) => UserAddress.fromJson(a)).toList();
          if (_selectedAddress == null ||
              !_allAddresses.any((a) => a.id == _selectedAddress!.id)) {
            _selectedAddress = _allAddresses.firstWhere(
              (a) => a.isDefault,
              orElse: () => _allAddresses.first,
            );
          }
        });
      } else {
        setState(() {
          _allAddresses = [];
          _selectedAddress = null;
        });
      }
    } catch (e) {
      debugPrint("Error fetching addresses: $e");
    }
  }

  Future<void> _processPayment() async {
    final cart = ref.read(cartProvider).where((item) => item.isSelected).toList();
    final total = ref.read(cartProvider.notifier).totalAmount;

    if (cart.isEmpty) return;

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a shipping address")),
      );
      return;
    }

    setState(() => _isLoading = true);

    int? orderId;
    try {
      // 1. Create the order first
      final orderData = await ApiService.post('orders/', {
        'items': cart
            .map((item) => {
                  'product': item.product['id'],
                  'quantity': item.quantity,
                })
            .toList(),
        'payment_gateway': _selectedMethod,
        'shipping_address_id': _selectedAddress!.id,
      });

      orderId = orderData['id'] as int;

      // 2. Process payment — if this throws, we cancel the order below
      if (_selectedMethod == 'stripe') {
        await _handleStripe(orderId);
      } else if (_selectedMethod == 'khalti') {
        await _handleKhalti(orderId, total);
      } else if (_selectedMethod == 'esewa') {
        await _handleEsewa(orderId, total);
      }
    } catch (e) {
      // Payment failed or was cancelled by the user.
      // Mark the order as 'failed' so it doesn't show as a ghost "pending" order.
      if (orderId != null) {
        try {
          await ApiService.post('orders/$orderId/cancel/', {});
        } catch (_) {}
      }
      if (mounted) {
        ErrorHelper.showSnackBarError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleStripe(int orderId) async {
    try {
      final response = await ApiService.post(
        'orders/$orderId/create-stripe-payment-intent/',
        {},
      );
      final clientSecret = response['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'KissanConnect',
          style: ThemeMode.light,
        ),
      );

      await Stripe.instance.presentPaymentSheet();
      _onPaymentSuccess();
    } on StripeException catch (e) {
      // User dismissed payment sheet — rethrow so _processPayment cancels the order
      if (e.error.code == FailureCode.Canceled) {
        throw Exception('Payment was cancelled.');
      }
      rethrow;
    }
  }

  Future<void> _handleKhalti(int orderId, double amount) async {
    try {
      final Map<String, dynamic> response = await ApiService.post(
        'orders/$orderId/initiate-khalti-payment/',
        {
          'return_url': 'https://kissan-connect-application.onrender.com/payment-success/',
        },
      );

      final String? paymentUrl = response['payment_url'] as String?;
      final String? pidx = response['pidx'] as String?;

      if (paymentUrl == null || pidx == null) {
        throw Exception("Backend did not return a payment URL. Response: $response");
      }

      final Uri uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showKhaltiVerificationDialog(orderId, pidx);
        }
      } else {
        throw Exception("Could not launch URL: $paymentUrl");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleEsewa(int orderId, double amount) async {
    final completer = Completer<void>();

    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          clientId: Constants.esewaClientId,
          secretId: Constants.esewaSecretKey,
          environment: Environment.test,
        ),
        esewaPayment: EsewaPayment(
          productId: orderId.toString(),
          productName: "Order #$orderId",
          productPrice: amount.toStringAsFixed(2),
          callbackUrl: "${Constants.apiBaseUrl}/api/esewa-callback/",
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult result) async {
          debugPrint(":::eSewa SUCCESS::: => $result");
          try {
            await ApiService.post(
              'orders/$orderId/verify-esewa-payment/',
              {'refId': result.refId},
            );
            _onPaymentSuccess();
            completer.complete();
          } catch (e) {
            completer.completeError(e);
          }
        },
        onPaymentFailure: (data) {
          debugPrint(":::eSewa FAILURE::: => $data");
          completer.completeError(Exception("eSewa payment failed: $data"));
        },
        onPaymentCancellation: (data) {
          debugPrint(":::eSewa CANCELLATION::: => $data");
          completer.completeError(Exception("Payment cancelled by user."));
        },
      );
    } catch (e) {
      completer.completeError(e);
    }

    return completer.future;
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
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ApiService.post('orders/$orderId/cancel/', {});
              } catch (_) {}
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() => _isLoading = true);
              try {
                await ApiService.post(
                  'orders/$orderId/verify-khalti-payment/',
                  {'pidx': pidx},
                );
                _onPaymentSuccess();
              } catch (e) {
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  ErrorHelper.showSnackBarError(context, e, prefix: "Verification Failed");
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
    ref.read(cartProvider.notifier).clearSelectedItems();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Order Placed! "),
        content: const Text("Your payment was successful and your order is confirmed."),
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

  void _showAddressSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Delivery Address",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allAddresses.length,
                  itemBuilder: (context, index) {
                    final addr = _allAddresses[index];
                    final isSelected = _selectedAddress?.id == addr.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: AppTheme.primaryGreen,
                      ),
                      title: Text(addr.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${addr.summary}\n${addr.phoneNumber}"),
                      isThreeLine: true,
                      onTap: () {
                        setState(() => _selectedAddress = addr);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add_location_alt_outlined, color: AppTheme.primaryGreen),
                title: const Text(
                  "Deliver to New Address",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddAddressScreen()),
                  );
                  if (result == true) _fetchDefaultAddress();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressSection() {
    if (_selectedAddress == null) {
      return InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAddressScreen()),
          );
          if (result == true) _fetchDefaultAddress();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: const Row(
            children: [
              Icon(Icons.add_location_alt_outlined, color: AppTheme.primaryGreen),
              SizedBox(width: 12),
              Text("Add Shipping Address",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              Spacer(),
              Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppTheme.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(_selectedAddress!.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(onPressed: _showAddressSelectionModal, child: const Text("Change")),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Text(_selectedAddress!.summary,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: Text(_selectedAddress!.phoneNumber,
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
        ],
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
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppTheme.primaryGreen.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryGreen : Colors.grey),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(cartProvider);
    final total = ref.watch(cartProvider.notifier).totalAmount;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const CustomAppBar(title: "Checkout"),
      body: BlurLoadingOverlay(
        isLoading: _isLoading,
        child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Payment Method",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildPaymentOption('stripe', 'Stripe (Card)', Icons.credit_card),
                  _buildPaymentOption('khalti', 'Khalti', Icons.account_balance_wallet),
                  _buildPaymentOption('esewa', 'eSewa', Icons.wallet),
                  const SizedBox(height: 24),
                  const Text("Shipping Address",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildAddressSection(),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Payable"),
                            Text(
                              "Rs. ${total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Pay Now",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
