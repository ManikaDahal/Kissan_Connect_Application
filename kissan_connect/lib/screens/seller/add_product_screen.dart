import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kissan_connect/services/api_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _weightController = TextEditingController();

  File? _image;
  String? _selectedCategory;
  String _selectedUnitType = 'piece';
  List<dynamic> _categories = [];
  bool _isLoading = false;

  final List<Map<String, String>> _unitTypes = [
    {'value': 'kg', 'label': 'kg (Kilograms)'},
    {'value': 'g', 'label': 'g (Grams)'},
    {'value': 'litre', 'label': 'L (Litre)'},
    {'value': 'ml', 'label': 'mL (Millilitre)'},
    {'value': 'piece', 'label': 'Piece'},
    {'value': 'pack', 'label': 'Pack'},
    {'value': 'bag', 'label': 'Bag'},
    {'value': 'bottle', 'label': 'Bottle'},
    {'value': 'box', 'label': 'Box'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _retrieveLostData();
  }

  Future<void> _retrieveLostData() async {
    final response = await ImagePicker().retrieveLostData();
    if (response.isEmpty) return;
    if (response.file != null) {
      setState(() {
        _image = File(response.file!.path);
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await ApiService.get('products/categories/');
      setState(() => _categories = response);
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> _pickImage() async {
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
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    }
  }

  Future<void> _showSuggestCategoryDialog() async {
    final nameController = TextEditingController();
    final reasonController = TextEditingController();
    final suggestFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Suggest New Category", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: suggestFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Category Name",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Why is this category needed?",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? "Required" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!suggestFormKey.currentState!.validate()) return;
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await ApiService.post('products/seller/category-suggestions/', {
                  'name': nameController.text.trim(),
                  'reason': reasonController.text.trim(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Category suggestion submitted! Admin will review it.")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProduct() async {
    if (!_formKey.currentState!.validate() ||
        _image == null ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select an image"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fields = {
        'name': _nameController.text,
        'description': _descController.text,
        'price': _priceController.text,
        if (_discountPriceController.text.isNotEmpty)
          'discount_price': _discountPriceController.text,
        'stock': _stockController.text,
        'weight': _weightController.text,
        'category': _selectedCategory!,
        'unit_type': _selectedUnitType,
      };

      final files = {'image': _image!.path};

      await ApiService.postMultipart(
        'products/seller/my-items/',
        fields,
        files,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add New Product"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[400]!),
                        ),
                        child: _image == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, size: 40),
                                  Text("Upload Product Image"),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_image!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Product Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategory,
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem<String>(
                              value: c['id'].toString(),
                              child: Text(c['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategory = v),
                      validator: (v) => v == null ? "Required" : null,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showSuggestCategoryDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green.shade300, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.green.shade50,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Can't find your category? Suggest one to admin",
                                style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Price (Rs.)",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Initial Stock",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _discountPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: "Discount Price (Optional) (Rs.)",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _discountPriceController.clear();
                          },
                          tooltip: "Remove Discount",
                        ),
                      ),
                      validator: (v) {
                        if (v != null && v.isNotEmpty) {
                          final val = double.tryParse(v);
                          if (val == null) return "Enter a valid price";
                          if (val <= 0) return "Discount price must be greater than zero";
                          final normalPrice = double.tryParse(_priceController.text);
                          if (normalPrice != null && val >= normalPrice) {
                            return "Discount price must be less than normal price";
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: "Net Amount (e.g. 1, 500)",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Unit Type",
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedUnitType,
                      items: _unitTypes
                          .map(
                            (u) => DropdownMenuItem<String>(
                              value: u['value'],
                              child: Text(u['label']!),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedUnitType = v!),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green,
                      ),
                      child: const Text(
                        "Save Product",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
