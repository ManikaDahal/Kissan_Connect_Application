import 'package:flutter/material.dart';
import 'package:kissan_connect/core/models/address_model.dart';
import 'package:kissan_connect/services/api_service.dart';

class AddAddressScreen extends StatefulWidget {
  final UserAddress? address;
  const AddAddressScreen({super.key, this.address});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _houseController = TextEditingController();
  String? _selectedProvince;
  bool _isDefault = false;
  bool _isLoading = false;

  final List<String> _provinces = [
    'Koshi',
    'Madhesh',
    'Bagmati',
    'Gandaki',
    'Lumbini',
    'Karnali',
    'Sudurpashchim',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _nameController.text = widget.address!.fullName;
      _phoneController.text = widget.address!.phoneNumber;
      _cityController.text = widget.address!.city;
      _areaController.text = widget.address!.area;
      _houseController.text = widget.address!.houseNo ?? '';
      _selectedProvince = widget.address!.province;
      _isDefault = widget.address!.isDefault;
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate() || _selectedProvince == null) {
      if (_selectedProvince == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a province")),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final addressData = {
      'full_name': _nameController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'province': _selectedProvince,
      'city': _cityController.text.trim(),
      'area': _areaController.text.trim(),
      'house_no': _houseController.text.trim(),
      'is_default': _isDefault,
    };

    try {
      if (widget.address != null) {
        await ApiService.patch('users/addresses/${widget.address!.id}/', addressData);
      } else {
        await ApiService.post('users/addresses/', addressData);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? "Add New Address" : "Edit Address"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_nameController, "Full Name", Icons.person_outline),
              _buildTextField(_phoneController, "Phone Number", Icons.phone_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedProvince,
                decoration: InputDecoration(
                  labelText: "Province",
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                items: _provinces.map((p) {
                  return DropdownMenuItem(value: p, child: Text("$p Province"));
                }).toList(),
                onChanged: (val) => setState(() => _selectedProvince = val),
                validator: (val) => val == null ? "Required" : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(_cityController, "City", Icons.location_city_outlined),
              _buildTextField(_areaController, "Area/Neighborhood", Icons.place_outlined),
              _buildTextField(_houseController, "House No. / Landmark (Optional)",
                  Icons.home_outlined,
                  required: false),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text("Set as Default Shipping Address"),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
                activeColor: Colors.green,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.address == null ? "Save Address" : "Update Address",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
        ),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) return "Required";
                return null;
              }
            : null,
      ),
    );
  }
}
