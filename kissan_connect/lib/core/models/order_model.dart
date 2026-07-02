import 'address_model.dart';

class OrderModel {
  final int id;
  final String userEmail;
  final double totalAmount;
  final String status;
  final String paymentGateway;
  final String? transactionId;
  final List<OrderItemModel> items;
  final UserAddress? shippingAddress;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userEmail,
    required this.totalAmount,
    required this.status,
    required this.paymentGateway,
    this.transactionId,
    required this.items,
    this.shippingAddress,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userEmail: json['user_email'] ?? '',
      totalAmount: double.parse(json['total_amount']?.toString() ?? '0.0'),
      status: json['status'] ?? 'pending',
      paymentGateway: json['payment_gateway'] ?? 'cod',
      transactionId: json['transaction_id'],
      items: (json['items'] as List?)
              ?.map((i) => OrderItemModel.fromJson(i))
              .toList() ??
          [],
      shippingAddress: json['shipping_address'] != null
          ? UserAddress.fromJson(json['shipping_address'])
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }
}

class OrderItemModel {
  final int id;
  final int? productId;
  final String productName;
  final int quantity;
  final double price;
  final String status;

  OrderItemModel({
    required this.id,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.status = 'pending',
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'],
      productId: json['product'],
      productName: json['product_name'] ?? 'Deleted Product',
      quantity: json['quantity'] ?? 1,
      price: double.parse(json['price']?.toString() ?? '0.0'),
      status: json['status'] ?? 'pending',
    );
  }
}
