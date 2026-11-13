class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.country,
    required this.city,
    required this.street,
    required this.building,
    this.premises,
    required this.isDefault,
  });

  final int id;
  final String label;
  final String country;
  final String city;
  final String street;
  final String building;
  final String? premises;
  final bool isDefault;

  String get formattedAddress => [
    street,
    building,
    if (premises?.isNotEmpty == true) premises!,
    city,
    country,
  ].where((part) => part.trim().isNotEmpty).join(', ');

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: (json['id'] as num).toInt(),
    label: json['label'] as String? ?? 'Home',
    country: json['country'] as String? ?? '',
    city: json['city'] as String? ?? '',
    street: json['street'] as String? ?? '',
    building: json['building'] as String? ?? '',
    premises: json['premises'] as String?,
    isDefault: json['isDefault'] as bool? ?? false,
  );

  Map<String, dynamic> toJson({bool? defaultOverride}) => {
    'label': label,
    'country': country,
    'city': city,
    'street': street,
    'building': building,
    'premises': premises,
    'isDefault': defaultOverride ?? isDefault,
  };
}
