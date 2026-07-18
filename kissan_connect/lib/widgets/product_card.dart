import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissan_connect/core/providers/cart_provider.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import '../theme/app_theme.dart';
import 'package:kissan_connect/services/api_service.dart';

class ProductCard extends ConsumerWidget {
  final dynamic product;
  final bool horizontal;
  final VoidCallback? onPop;

  const ProductCard({
    super.key,
    required this.product,
    this.horizontal = false,
    this.onPop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        await RouteGenerator.navigateToPage(
          context,
          Routes.productDetailsRoute,
          arguments: product,
        );
        if (onPop != null) {
          onPop!();
        }
      },
      child: Container(
        width: horizontal ? 160 : null,
        margin: horizontal ? const EdgeInsets.only(right: 16) : null,
        child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: product['image'] != null && product['image'].toString().isNotEmpty
                        ? Image.network(
                            ApiService.getImageUrl(product['image']), 
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 30),
                            ),
                          )
                        : const Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
                  ),
                  if (product['discount_price'] != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${(((double.parse(product['price'].toString()) - double.parse(product['discount_price'].toString())) / double.parse(product['price'].toString())) * 100).round()}% OFF",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? "Product",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    product['distance'] != null
                        ? "${product['shop_name'] ?? "Store"} • ${product['distance']} km away"
                        : (product['shop_name'] ?? "Store"),
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    maxLines: 1,
                  ),
                  if (product['average_rating'] != null && (product['average_rating'] is num ? product['average_rating'] : double.tryParse(product['average_rating'].toString()) ?? 0) > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          (product['average_rating'] is num ? product['average_rating'] : double.tryParse(product['average_rating'].toString()) ?? 0).toStringAsFixed(1),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        if (product['total_reviews'] != null && product['total_reviews'] > 0)
                          Text(
                            " (${product['total_reviews']})",
                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final discountPrice = product['discount_price'];
                            if (discountPrice != null) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Rs. $discountPrice",
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "Rs. ${product['price']}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Text(
                              "Rs. ${product['price']}",
                              style: const TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            );
                          }
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          try {
                            await ref.read(cartProvider.notifier).addToCart(product);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${product['name'] ?? 'Product'} added to cart"),
                                  backgroundColor: AppTheme.primaryGreen,
                                  duration: const Duration(milliseconds: 700),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll("Exception: ", "")),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
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
