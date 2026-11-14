import 'dart:convert';

import '../core/api_constants.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AdminReport {
  final int id;
  final String type;
  final String description;
  final String status;
  final String createdAt;
  final int orderId;
  final String orderUser;
  final int? mealId;
  final String? mealName;
  final int? restaurantId;
  final String? restaurantName;
  final int accountId;

  AdminReport({
    required this.id,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.orderId,
    required this.orderUser,
    this.mealId,
    this.mealName,
    this.restaurantId,
    this.restaurantName,
    required this.accountId,
  });

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
        id: (json['id'] as num).toInt(),
        type: (json['type'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
        status: (json['status'] ?? 'Pending').toString(),
        createdAt: (json['createdAt'] ?? '').toString(),
        orderId: (json['orderId'] as num).toInt(),
        orderUser: (json['orderUser'] ?? '').toString(),
        mealId: (json['mealId'] as num?)?.toInt(),
        mealName: json['mealName']?.toString(),
        restaurantId: (json['restaurantId'] as num?)?.toInt(),
        restaurantName: json['restaurantName']?.toString(),
        accountId: (json['accountId'] as num).toInt(),
      );
}

class AdminRating {
  final int id;
  final int orderId;
  final int score;
  final String? comment;
  final String createdAt;
  final String orderUser;
  final double totalPrice;

  AdminRating({
    required this.id,
    required this.orderId,
    required this.score,
    this.comment,
    required this.createdAt,
    required this.orderUser,
    required this.totalPrice,
  });

  factory AdminRating.fromJson(Map<String, dynamic> json) => AdminRating(
        id: (json['id'] as num).toInt(),
        orderId: (json['orderId'] as num).toInt(),
        score: (json['score'] as num).toInt(),
        comment: json['comment']?.toString(),
        createdAt: (json['createdAt'] ?? '').toString(),
        orderUser: (json['orderUser'] ?? '').toString(),
        totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      );
}

class AdminReportsService {
  Future<List<AdminReport>> getReports() async {
    final res = await ApiClient.send('GET', ApiConstants.adminReports);
    final decoded = jsonDecode(res.body);
    final List<dynamic> list = decoded is List
        ? decoded
        : (decoded is Map && decoded['items'] is List)
            ? decoded['items'] as List
            : <dynamic>[];
    return list.map((e) => AdminReport.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AdminRating>> getRatings() async {
    final res = await ApiClient.send('GET', ApiConstants.adminRatings);
    final decoded = jsonDecode(res.body);
    final List<dynamic> list = decoded is List
        ? decoded
        : (decoded is Map && decoded['items'] is List)
            ? decoded['items'] as List
            : <dynamic>[];
    return list.map((e) => AdminRating.fromJson(e as Map<String, dynamic>)).toList();
  }
}
