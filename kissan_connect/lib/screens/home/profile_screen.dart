import 'package:flutter/material.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/core/utils/route_const.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';
import 'package:kissan_connect/screens/profile/order_history_screen.dart';
import 'package:kissan_connect/screens/profile/address_book_screen.dart';
import 'package:kissan_connect/screens/profile/seller_registration_screen.dart';
import 'package:kissan_connect/screens/seller/seller_dashboard_screen.dart';
import 'package:kissan_connect/widgets/shimmer_loading.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  bool isGuest = false;
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
    final bool loggedIn = await ApiService.isLoggedIn();
    if (!loggedIn) {
      if (mounted) {
        setState(() {
          isGuest = true;
          isLoading = false;
        });
      }
      return;
    }

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

  void _showSupportDialog() {
    final TextEditingController supportController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Help & Support"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Write your query to KissanConnect Admin:", style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: supportController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Type description or suggestions...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
            ],
          ),
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
                final message = supportController.text.trim();
                if (message.isEmpty) return;
                
                Navigator.of(context).pop();
                
                // Show a temporary snackbar while sending
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Sending ticket..."),
                    duration: Duration(milliseconds: 800),
                  ),
                );

                try {
                  await ApiService.post('users/support/ticket/', {
                    'message': message,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ticket successfully saved! Admin notified."),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed: ${e.toString()}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
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
          ? const ProfileScreenShimmer()
          : isGuest
              ? _buildGuestView()
              : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        errorMessage ?? "Error loading profile.",
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Premium Green Gradient Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade800, Colors.green.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 45, color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userName ?? "User Name",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail ?? "user@example.com",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Premium Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                userRole == 'seller' ? Icons.storefront : Icons.shopping_cart,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                userRole == 'seller' ? "VERIFIED VENDOR" : "RETAIL BUYER",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Label Categories
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      "Shopping Profile",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  
                  // Card Layer Item List 1: Orders and Destinations
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildProfileItem(
                          Icons.shopping_bag_outlined,
                          "My Orders",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildProfileItem(
                          Icons.location_on_outlined,
                          "Shipping Address",
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddressBookScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      "Business Center",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),

                  // Card Layer Item List 2: Seller Dashboard
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        if ((userRole == 'seller' && isSellerVerified) || sellerStatus == 'approved')
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
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      "Support & Account",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),

                  // Card Layer Item List 3: System Help / Exit
                  Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        _buildProfileItem(
                          Icons.help_outline,
                          "Help & Support",
                          _showSupportDialog,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
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
                  const SizedBox(height: 24),
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

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              "Guest User",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Log in or sign up to view your profile, track orders, and manage settings.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, Routes.loginRoute);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Log In / Sign Up", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
