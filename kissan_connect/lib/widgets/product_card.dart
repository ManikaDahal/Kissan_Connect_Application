import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kissan_connect/core/providers/cart_provider.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'package:kissan_connect/core/utils/route_generator.dart';
import '../theme/app_theme.dart';

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
                            product['image'], 
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
                  // No favorite icon here as requested

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
                    product['shop_name'] ?? "Store",
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rs. ${product['price']}",
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(cartProvider.notifier).addToCart(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${product['name'] ?? 'Product'} added to cart"),
                              backgroundColor: AppTheme.primaryGreen,
                              duration: const Duration(milliseconds: 700),
                            ),
                          );
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
