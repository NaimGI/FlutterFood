class DeliveryProfile {
  final String phone;
  final String country;
  final String city;
  final String street;
  final String building;
  final double? latitude;
  final double? longitude;

  const DeliveryProfile({
    required this.phone,
    required this.country,
    required this.city,
    required this.street,
    required this.building,
    this.latitude,
    this.longitude,
  });

  bool get isComplete => phone.isNotEmpty && city.isNotEmpty && street.isNotEmpty && building.isNotEmpty;
  String get addressLabel => [street, building, city, country].where((v) => v.isNotEmpty).join(', ');

  Map<String, dynamic> toJson() => {
        'phone': phone, 'country': country, 'city': city, 'street': street,
        'building': building, 'latitude': latitude, 'longitude': longitude,
      };

  factory DeliveryProfile.fromJson(Map<String, dynamic> json) => DeliveryProfile(
        phone: (json['phone'] ?? '').toString(), country: (json['country'] ?? '').toString(),
        city: (json['city'] ?? '').toString(), street: (json['street'] ?? '').toString(),
        building: (json['building'] ?? '').toString(),
        latitude: (json['latitude'] as num?)?.toDouble(), longitude: (json['longitude'] as num?)?.toDouble(),
      );
}
