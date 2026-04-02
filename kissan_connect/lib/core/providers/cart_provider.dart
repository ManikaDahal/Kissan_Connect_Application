import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final dynamic product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addToCart(dynamic product) {
    final index = state.indexWhere((item) => item.product['id'] == product['id']);
    if (index != -1) {
      state[index].quantity++;
      state = [...state];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeFromCart(int productId) {
    state = state.where((item) => item.product['id'] != productId).toList();
  }

  void updateQuantity(int productId, int delta) {
    final index = state.indexWhere((item) => item.product['id'] == productId);
    if (index != -1) {
      state[index].quantity += delta;
      if (state[index].quantity <= 0) {
        removeFromCart(productId);
      } else {
        state = [...state];
      }
    }
  }

  void clearCart() {
    state = [];
  }

  double get totalAmount {
    return state.fold(0, (sum, item) => sum + (double.parse(item.product['price'].toString()) * item.quantity));
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
