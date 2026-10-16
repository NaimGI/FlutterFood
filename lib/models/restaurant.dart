import '../core/app_images.dart';

class Restaurant {
  final int id;
  final String name;
  final String category;
  final List<dynamic>? meals;
  final double? rating;

  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    this.meals,
    this.rating,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'] as int,
        name: (json['name'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        meals: json['meals'] as List<dynamic>?,
        rating: (json['rating'] as num?)?.toDouble(),
      );

  String get imageUrl => AppImages.forId(id);
}