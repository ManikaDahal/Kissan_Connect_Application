import 'package:flutter/material.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';
import 'package:kissan_connect/screens/profile/order_history_screen.dart';
import 'package:kissan_connect/screens/profile/address_book_screen.dart';
import 'package:kissan_connect/screens/profile/seller_registration_screen.dart';
import 'package:kissan_connect/screens/seller/seller_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  String? userName;
  String? userEmail;
  String? errorMessage;
  String? userRole;
  bool isSellerVerified = false;
  String? sellerStatus;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await ApiService.get('users/profile/');
      if (mounted) {
        setState(() {
          userName =
              response['full_name'] ??
              response['name'] ??
              response['first_name'];
          userEmail = response['email'];
          userRole = response['role'];
          isSellerVerified = response['is_seller_verified'] ?? false;
          isLoading = false;
        });
        _fetchSellerStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchSellerStatus() async {
    try {
      final statusResponse = await ApiService.get('users/seller/status/');
      if (mounted) {
        setState(() {
          sellerStatus = statusResponse['status'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching seller status: $e");
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await ApiService.clearTokens();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    Routes.loginRoute,
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Profile"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        errorMessage ?? "Error loading profile. Please check your internet connection.",
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  Text(
                    userName ?? "User Name",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail ?? "user@example.com",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  _buildProfileItem(
                    Icons.shopping_bag_outlined,
                    "My Orders",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                    ),
                  ),
                  _buildProfileItem(
                    Icons.location_on_outlined,
                    "Shipping Address",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddressBookScreen()),
                    ),
                  ),
                  _buildProfileItem(
                    Icons.payment_outlined,
                    "Payment Methods",
                    () {},
                  ),
                  const Divider(height: 30),
                  
                  // Seller Section
                  if (userRole == 'seller' && isSellerVerified)
                    _buildProfileItem(
                      Icons.dashboard_customize_outlined,
                      "Seller Dashboard",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SellerDashboardScreen()),
                        );
                      },
                      textColor: Colors.green.shade700,
                      iconColor: Colors.green.shade700,
                    )
                  else if (sellerStatus == 'pending')
                    _buildProfileItem(
                      Icons.hourglass_empty,
                      "Application Pending",
                      () {},
                      textColor: Colors.orange,
                      iconColor: Colors.orange,
                    )
                  else
                    _buildProfileItem(
                      Icons.storefront_outlined,
                      "Become a Seller",
                      () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SellerRegistrationScreen()),
                        );
                        if (result == true) {
                          _fetchProfileData();
                        }
                      },
                      textColor: Colors.blue,
                      iconColor: Colors.blue,
                    ),
                  
                  const Divider(height: 30),
                  _buildProfileItem(Icons.settings_outlined, "Settings", () {}),
                  _buildProfileItem(
                    Icons.help_outline,
                    "Help & Support",
                    () {},
                  ),
                  _buildProfileItem(
                    Icons.logout,
                    "Logout",
                    _showLogoutDialog,
                    textColor: Colors.red,
                    iconColor: Colors.red,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.green).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? Colors.green),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
