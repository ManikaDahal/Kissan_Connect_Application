import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer wrapper that applies the animated gradient effect.
class ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const ShimmerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// A simple box placeholder used as a building block for skeletons.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer skeleton for a single product card (2-column grid).
class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          ShimmerBox(
            width: double.infinity,
            height: 130,
            borderRadius: 16,
          ),
          const SizedBox(height: 10),
          // Product name line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ShimmerBox(width: double.infinity, height: 12),
          ),
          const SizedBox(height: 6),
          // Short line (seller/category)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ShimmerBox(width: 80, height: 10),
          ),
          const SizedBox(height: 8),
          // Price and button row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 60, height: 14),
                ShimmerBox(width: 32, height: 32, borderRadius: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer grid of product cards (replaces the full-screen spinner).
class ProductGridShimmer extends StatelessWidget {
  final int itemCount;

  const ProductGridShimmer({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => const ProductCardShimmer(),
      ),
    );
  }
}

/// Shimmer placeholder for a single horizontal product card (featured).
class HorizontalProductCardShimmer extends StatelessWidget {
  const HorizontalProductCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: 150, height: 110, borderRadius: 16),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ShimmerBox(width: double.infinity, height: 12),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ShimmerBox(width: 60, height: 12),
          ),
        ],
      ),
    );
  }
}

/// Shimmer skeleton for the category circle items.
class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerBox(width: 60, height: 60, borderRadius: 30),
        const SizedBox(height: 8),
        ShimmerBox(width: 50, height: 10),
      ],
    );
  }
}

/// Full shimmer layout for the Home Screen's initial loading state.
class HomeScreenShimmer extends StatelessWidget {
  const HomeScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Search bar placeholder
            ShimmerBox(width: double.infinity, height: 52, borderRadius: 16),
            const SizedBox(height: 24),

            // Weather card placeholder
            ShimmerBox(width: double.infinity, height: 100, borderRadius: 16),
            const SizedBox(height: 24),

            // Categories title & see-all row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 100, height: 16),
                ShimmerBox(width: 55, height: 14),
              ],
            ),
            const SizedBox(height: 12),

            // Category circles
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (_, __) => Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: const CategoryShimmer(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Featured Products title
            ShimmerBox(width: 140, height: 16),
            const SizedBox(height: 12),

            // Horizontal featured products
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (_, __) => const HorizontalProductCardShimmer(),
              ),
            ),
            const SizedBox(height: 24),

            // All Products title
            ShimmerBox(width: 110, height: 16),
            const SizedBox(height: 12),

            // Product grid
            const ProductGridShimmer(itemCount: 4),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Shimmer for a full-screen grid loading state (used in CategoryProductsScreen).
class CategoryGridShimmer extends StatelessWidget {
  const CategoryGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => const ProductCardShimmer(),
      ),
    );
  }
}

/// Shimmer skeleton for the Profile Screen.
class ProfileScreenShimmer extends StatelessWidget {
  const ProfileScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header card
            ShimmerBox(width: double.infinity, height: 200, borderRadius: 24),
            const SizedBox(height: 24),
            // Section label
            ShimmerBox(width: 120, height: 14),
            const SizedBox(height: 12),
            // Menu card with 2 items
            ShimmerBox(width: double.infinity, height: 120, borderRadius: 16),
            const SizedBox(height: 20),
            // Section label
            ShimmerBox(width: 110, height: 14),
            const SizedBox(height: 12),
            // Menu card with 1 item
            ShimmerBox(width: double.infinity, height: 60, borderRadius: 16),
            const SizedBox(height: 20),
            // Section label
            ShimmerBox(width: 140, height: 14),
            const SizedBox(height: 12),
            // Menu card with 2 items
            ShimmerBox(width: double.infinity, height: 120, borderRadius: 16),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for the Order History Screen (list of order cards).
class OrderListShimmer extends StatelessWidget {
  final int itemCount;
  const OrderListShimmer({super.key, this.itemCount = 4});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order card
              ShimmerBox(width: double.infinity, height: 90, borderRadius: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton for the Address Book Screen.
class AddressListShimmer extends StatelessWidget {
  final int itemCount;
  const AddressListShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              ShimmerBox(width: 44, height: 44, borderRadius: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: double.infinity, height: 14),
                    const SizedBox(height: 8),
                    ShimmerBox(width: 150, height: 12),
                    const SizedBox(height: 6),
                    ShimmerBox(width: 200, height: 12),
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

/// Shimmer skeleton for the Seller Dashboard Screen.
class SellerDashboardShimmer extends StatelessWidget {
  const SellerDashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Earnings banner
            ShimmerBox(width: double.infinity, height: 100, borderRadius: 16),
            const SizedBox(height: 12),
            // Stat cards row
            Row(
              children: [
                Expanded(child: ShimmerBox(width: double.infinity, height: 90, borderRadius: 16)),
                const SizedBox(width: 12),
                Expanded(child: ShimmerBox(width: double.infinity, height: 90, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 16),
            // View orders button
            ShimmerBox(width: double.infinity, height: 50, borderRadius: 12),
            const SizedBox(height: 24),
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 120, height: 18),
                ShimmerBox(width: 80, height: 36, borderRadius: 8),
              ],
            ),
            const SizedBox(height: 16),
            // Product list items
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerBox(width: double.infinity, height: 90, borderRadius: 12),
            )),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for the Seller Orders Screen (list of order cards).
class SellerOrdersShimmer extends StatelessWidget {
  final int itemCount;
  const SellerOrdersShimmer({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              ShimmerBox(width: double.infinity, height: 44, borderRadius: 0),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Date
                    ShimmerBox(width: 160, height: 12),
                    const SizedBox(height: 12),
                    // Buyer info
                    Row(
                      children: [
                        ShimmerBox(width: 36, height: 36, borderRadius: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(width: 120, height: 14),
                              const SizedBox(height: 4),
                              ShimmerBox(width: 160, height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Item placeholder
                    ShimmerBox(width: double.infinity, height: 60, borderRadius: 12),
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

/// Shimmer skeleton for the Seller Earnings Screen.
class SellerEarningsShimmer extends StatelessWidget {
  const SellerEarningsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero balance card
            ShimmerBox(width: double.infinity, height: 130, borderRadius: 20),
            const SizedBox(height: 16),
            // Three stat cards
            Row(
              children: [
                Expanded(child: ShimmerBox(width: double.infinity, height: 100, borderRadius: 16)),
                const SizedBox(width: 10),
                Expanded(child: ShimmerBox(width: double.infinity, height: 100, borderRadius: 16)),
                const SizedBox(width: 10),
                Expanded(child: ShimmerBox(width: double.infinity, height: 100, borderRadius: 16)),
              ],
            ),
            const SizedBox(height: 24),
            // Transaction history title
            ShimmerBox(width: 160, height: 18),
            const SizedBox(height: 12),
            // Transaction cards
            ...List.generate(3, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerBox(width: double.infinity, height: 110, borderRadius: 16),
            )),
          ],
        ),
      ),
    );
  }
}

/// Shimmer skeleton for the Categories grid screen.
class CategoriesScreenShimmer extends StatelessWidget {
  const CategoriesScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => ShimmerBox(
          width: double.infinity,
          height: double.infinity,
          borderRadius: 16,
        ),
      ),
    );
  }
}
