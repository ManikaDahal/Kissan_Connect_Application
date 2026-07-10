import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:flutter/material.dart';

class CartItem {
  final dynamic product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]) {
    _initializeCart();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> _initializeCart() async {
    if (await ApiService.isLoggedIn()) {
      await fetchCart();
    }
  }

  Future<void> fetchCart() async {
    _isLoading = true;
    try {
      final response = await ApiService.get('cart/');
      if (response != null && response['items'] != null) {
        final List<dynamic> itemsData = response['items'];
        state = itemsData.map((item) => CartItem(
          product: item['product'],
          quantity: item['quantity'],
        )).toList();
      }
    } catch (e) {
      debugPrint("Error fetching cart: $e");
    } finally {
      _isLoading = false;
    }
  }

  Future<void> syncCartOnLogin() async {
    final localItems = [...state];
    
    // Push local items to backend
    for (var localItem in localItems) {
      try {
        await ApiService.post('cart/add/', {
          'product_id': localItem.product['id'],
          'quantity': localItem.quantity,
        });
      } catch (e) {
        debugPrint("Error syncing cart item: $e");
      }
    }
    
    // Now fetch the fully merged cart from backend
    await fetchCart();
  }

  Future<void> addToCart(dynamic product) async {
    final bool loggedIn = await ApiService.isLoggedIn();
    
    // Save old state for potential rollback
    final oldState = [...state];
    
    // Optimistic Update
    final index = state.indexWhere((item) => item.product['id'] == product['id']);
    if (index != -1) {
      state[index].quantity++;
      state = [...state];
    } else {
      state = [...state, CartItem(product: product)];
    }

    if (loggedIn) {
      try {
        await ApiService.post('cart/add/', {
          'product_id': product['id'],
          'quantity': 1,
        });
      } catch (e) {
        debugPrint("Error adding to persistent cart: $e");
        state = oldState;
        rethrow;
      }
    }
  }

  Future<void> removeFromCart(int productId) async {
    final bool loggedIn = await ApiService.isLoggedIn();
    
    // Optimistic Update
    state = state.where((item) => item.product['id'] != productId).toList();

    if (loggedIn) {
      try {
        await ApiService.delete('cart/remove/$productId/');
      } catch (e) {
        debugPrint("Error removing from persistent cart: $e");
      }
    }
  }

  Future<void> updateQuantity(int productId, int delta) async {
    final bool loggedIn = await ApiService.isLoggedIn();
    
    final index = state.indexWhere((item) => item.product['id'] == productId);
    if (index != -1) {
      final newQuantity = state[index].quantity + delta;
      
      if (newQuantity <= 0) {
        await removeFromCart(productId);
      } else {
        // Optimistic Update
        state[index].quantity = newQuantity;
        state = [...state];

        if (loggedIn) {
          try {
            await ApiService.post('cart/update/', {
              'product_id': productId,
              'quantity': newQuantity,
            });
          } catch (e) {
            debugPrint("Error updating persistent cart: $e");
          }
        }
      }
    }
  }

  Future<void> clearCart() async {
    final bool loggedIn = await ApiService.isLoggedIn();
    
    state = [];

    if (loggedIn) {
      try {
        await ApiService.delete('cart/clear/');
      } catch (e) {
        debugPrint("Error clearing persistent cart: $e");
      }
    }
  }

  double get totalAmount {
    return state.fold(0, (sum, item) {
      final product = item.product;
      final price = product['discount_price'] != null
          ? double.parse(product['discount_price'].toString())
          : double.parse(product['price'].toString());
      return sum + (price * item.quantity);
    });
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
