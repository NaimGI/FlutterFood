import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api_constants.dart';
import '../models/meal.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class MealItem {
  final int id;
  final String name;
  final int quantity;
  final double lineTotal;

  const MealItem(
      {required this.id,
      required this.name,
      required this.quantity,
      required this.lineTotal});
}

class MealService {
  Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'Authorization': 'Bearer $token',
      };

  Future<List<Meal>> getByRestaurant(int restaurantId) async {
    final token = await TokenStorage.read();
    if (token == null || token.isEmpty) {
      throw const ApiException('Session expired (401)', statusCode: 401);
    }

    final url =
        '${ApiConstants.mealsByRestaurant(restaurantId)}?t=${DateTime.now().millisecondsSinceEpoch}';

    try {
      debugPrint('➡️ GET $url');

      final res = await http
          .get(Uri.parse(url), headers: _headers(token))
          .timeout(const Duration(seconds: 15));

      debugPrint('⬅️ ${res.statusCode}: ${res.body}');

      if (res.statusCode == 401) {
        throw const ApiException('Session expired (401)', statusCode: 401);
      }
      if (res.statusCode == 404) return [];
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException('Failed to load meals (${res.statusCode})',
            statusCode: res.statusCode);
      }

      if (res.body.trim().isEmpty) return [];
      final decoded = jsonDecode(res.body);

      final List<dynamic> list = decoded is List
          ? decoded
          : (decoded is Map && decoded['meals'] is List)
              ? decoded['meals'] as List
              : (decoded is Map && decoded['data'] is List)
                  ? decoded['data'] as List
                  : <dynamic>[];

      return list
          .map((e) => Meal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Cannot reach server');
    } on TimeoutException {
      throw const ApiException('Request timed out');
    } on HandshakeException {
      throw const ApiException('SSL certificate error');
    } on FormatException {
      throw const ApiException('Invalid server response');
    }
  }

  Future<List<MealItem>> getByOrder(int orderId) async {
    final res = await ApiClient.send(
        'GET', ApiConstants.mealsByOrder(orderId),
        allow404: true);
    if (res.statusCode == 404 || res.body.trim().isEmpty) return [];
    final decoded = jsonDecode(res.body);
    final List<dynamic> list = decoded is List
        ? decoded
        : (decoded is Map && decoded['items'] is List)
            ? decoded['items'] as List
            : <dynamic>[];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      final price = m['price'];
      return MealItem(
        id: (m['id'] as num?)?.toInt() ?? 0,
        name: (m['meal'] ?? m['name'] ?? 'Item').toString(),
        quantity: ((m['quantity'] ?? 1) as num).toInt(),
        lineTotal: price is num
            ? price.toDouble()
            : double.tryParse('$price') ?? 0,
      );
    }).toList();
  }

  Future<void> create(
      {required String name,
      required String description,
      required double price,
      String? imageUrl,
      required int restaurantId}) async {
    await ApiClient.send('POST', ApiConstants.mealCreate, body: {
      'name': name,
      'description': description,
      'price': price,
      if (imageUrl != null && imageUrl.isNotEmpty) 'img': imageUrl,
      'restaurantId': restaurantId,
    });
  }

  Future<void> update(
      {required int id,
      required String name,
      required String description,
      required double price,
      String? imageUrl}) async {
    await ApiClient.send('PUT', ApiConstants.mealUpdate(id), body: {
      'name': name,
      'description': description,
      'price': price,
      if (imageUrl != null) 'img': imageUrl,
    });
  }

  Future<void> delete(int id) async {
    await ApiClient.send('DELETE', ApiConstants.mealDelete(id));
  }

  Future<void> addToOrder(
          {required int orderId,
          required int mealId,
          int quantity = 1}) async =>
      ApiClient.send('PATCH', ApiConstants.mealAddToOrder(orderId),
          body: {'mealId': mealId, 'quantity': quantity});

  Future<void> removeFromOrder(
          {required int orderId,
          required int mealId,
          int quantity = 1}) async =>
      ApiClient.send('DELETE', ApiConstants.mealRemoveFromOrder(orderId),
          body: {'mealId': mealId, 'quantity': quantity});
}
