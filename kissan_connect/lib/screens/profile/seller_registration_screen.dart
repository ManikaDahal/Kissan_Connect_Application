import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kissan_connect/services/api_service.dart';
import 'package:kissan_connect/widgets/custom_app_bar.dart';

class SellerRegistrationScreen extends StatefulWidget {
  const SellerRegistrationScreen({super.key});

  @override
  State<SellerRegistrationScreen> createState() => _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopDescController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _payoutIdController = TextEditingController();
  
  String _selectedGateway = 'esewa';
  File? _citizenshipFront;
  File? _citizenshipBack;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isFront) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          if (isFront) {
            _citizenshipFront = File(image.path);
          } else {
            _citizenshipBack = File(image.path);
          }
        });
      }
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_citizenshipFront == null || _citizenshipBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload both sides of your citizenship")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fields = {
        'shop_name': _shopNameController.text,
        'shop_description': _shopDescController.text,
        'shop_address': _shopAddressController.text,
        'payout_gateway': _selectedGateway,
        'payout_id': _payoutIdController.text,
      };

      final files = {
        'citizenship_front': _citizenshipFront!.path,
        'citizenship_back': _citizenshipBack!.path,
      };

      await ApiService.postMultipart('users/seller/apply/', fields, files);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Application submitted successfully!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Become a Seller"),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Register your Shop",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  const Text("Provide your business details and verification documents.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  
                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(labelText: "Shop Name", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Enter shop name" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _shopDescController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Shop Description", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Enter description" : null,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _shopAddressController,
                    decoration: const InputDecoration(labelText: "Shop Address", border: OutlineInputBorder()),
                    validator: (v) => v!.isEmpty ? "Enter shop address" : null,
                  ),
                  const SizedBox(height: 24),
                  
                  const Text("Identity Verification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildImagePicker("Front Side", _citizenshipFront, () => _pickImage(true))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildImagePicker("Back Side", _citizenshipBack, () => _pickImage(false))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  const Text("Payout Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedGateway,
                    decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Payout Gateway"),
                    items: const [
                      DropdownMenuItem(value: 'esewa', child: Text("eSewa")),
                      DropdownMenuItem(value: 'stripe', child: Text("Stripe")),
                    ],
                    onChanged: (v) => setState(() => _selectedGateway = v!),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _payoutIdController,
                    decoration: InputDecoration(
                      labelText: _selectedGateway == 'esewa' ? "eSewa Phone Number" : "Stripe Account ID",
                      border: const OutlineInputBorder()
                    ),
                    validator: (v) => v!.isEmpty ? "Enter payout ID" : null,
                  ),
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitApplication,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text("Submit Application"),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildImagePicker(String label, File? image, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: image == null 
              ? const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 30)
              : ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(image, fit: BoxFit.cover)),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
