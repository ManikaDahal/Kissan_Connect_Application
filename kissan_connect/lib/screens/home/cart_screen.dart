import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissan_connect/core/providers/cart_provider.dart';
import 'package:kissan_connect/core/providers/nav_provider.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/theme/app_theme.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const CustomAppBar(title: "Your Cart"),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Your cart is empty", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(navProvider.notifier).state = 0;
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                    child: const Text("Start Shopping", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: item.product['image'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(item.product['image'], fit: BoxFit.cover),
                                      )
                                    : const Icon(Icons.shopping_bag, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product['name'] ?? "Product",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text(
                                      "Rs. ${item.product['price']}",
                                      style: const TextStyle(color: AppTheme.primaryGreen),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryGreen),
                                    onPressed: () => cartNotifier.updateQuantity(item.product['id'], -1),
                                  ),
                                  Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
                                    onPressed: () => cartNotifier.updateQuantity(item.product['id'], 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Amount", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            "Rs. ${cartNotifier.totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            final bool loggedIn = await ApiService.isLoggedIn();
                            if (!loggedIn) {
                              if (context.mounted) {
                                _showAuthRequiredBottomSheet(context);
                              }
                            } else {
                              if (context.mounted) {
                                Navigator.pushNamed(context, Routes.checkoutRoute);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                          child: const Text("Proceed to Checkout", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _showAuthRequiredBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                // Lock Icon with premium styling
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 40,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Login Required",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You need to sign in or create an account to proceed to checkout and secure your order.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.pushNamed(context, Routes.loginRoute);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Log In / Sign Up",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Continue Browsing Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Continue Browsing",
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
