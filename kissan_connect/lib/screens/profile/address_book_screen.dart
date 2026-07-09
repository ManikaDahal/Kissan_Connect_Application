import 'package:flutter/material.dart';
import 'package:kissan_connect/core/models/address_model.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/widgets/shimmer_loading.dart';
import 'add_address_screen.dart';

class AddressBookScreen extends StatefulWidget {
  final bool selectMode; // If true, tapping an address returns it
  const AddressBookScreen({super.key, this.selectMode = false});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  List<UserAddress> addresses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      final response = await ApiService.get('users/addresses/');
      List<dynamic> listContent = [];

      if (response is List) {
        listContent = response;
      } else if (response is Map && response.containsKey('results')) {
        listContent = response['results'];
      }

      setState(() {
        addresses = listContent.map((a) => UserAddress.fromJson(a)).toList();
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteAddress(int id) async {
    try {
      await ApiService.delete('users/addresses/$id/');
      _fetchAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Addresses",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: isLoading
          ? const AddressListShimmer()
          : addresses.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return _buildAddressCard(address);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAddressScreen()),
          );
          if (result == true) _fetchAddresses();
        },
        label: const Text(
          "Add New Address",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off_outlined, size: 64, color: Colors.green.shade200),
          ),
          const SizedBox(height: 16),
          const Text(
            "No Saved Addresses",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            "Add a shipping address to place orders.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(UserAddress address) {
    final isDefault = address.isDefault;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault ? Colors.green : Colors.grey.shade200,
          width: isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.selectMode ? () => Navigator.pop(context, address) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pin Avatar Indicator
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDefault ? Colors.green : Colors.grey).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  color: isDefault ? Colors.green : Colors.grey.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Address Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            address.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              "Default",
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      address.phoneNumber,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${address.houseNo != null && address.houseNo!.isNotEmpty ? '${address.houseNo}, ' : ''}${address.area}, ${address.city}",
                      style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${address.province} Province",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Compact Actions on the Right
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Colors.green.shade600, size: 22),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddAddressScreen(address: address),
                        ),
                      );
                      if (result == true) _fetchAddresses();
                    },
                    tooltip: "Edit Address",
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Address"),
                          content: const Text("Are you sure you want to remove this address?"),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteAddress(address.id!);
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              child: const Text("Delete", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: "Delete Address",
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
