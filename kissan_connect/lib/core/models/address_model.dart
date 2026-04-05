class UserAddress {
  final int? id;
  final String fullName;
  final String phoneNumber;
  final String province;
  final String city;
  final String area;
  final String? houseNo;
  final bool isDefault;

  UserAddress({
    this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.province,
    required this.city,
    required this.area,
    this.houseNo,
    this.isDefault = false,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    return UserAddress(
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      province: json['province'],
      city: json['city'],
      area: json['area'],
      houseNo: json['house_no'],
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'province': province,
      'city': city,
      'area': area,
      'house_no': houseNo,
      'is_default': isDefault,
    };
  }

  String get fullAddress => "$fullName, $city, $province";
  String get summary => "$area, $city, $province";
}
