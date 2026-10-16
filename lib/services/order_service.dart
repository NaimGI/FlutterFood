import 'dart:convert';

import '../core/api_constants.dart';
import '../models/order.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class OrderService {
  /// POST api/order/create — returns the new order id.
  /// Backend answers 201 with Location header or plain id body.
  Future<int> create({
    required int cartId,
    required int accountId,
    double totalPrice = 0,
    String? notes,
  }) async {
    final res = await ApiClient.send(
      'POST',
      ApiConstants.orderCreate,
      body: {
        'notes': notes ?? '',
        'cartId': cartId,
        'accountId': accountId,
        'totalPrice': double.parse(totalPrice.toStringAsFixed(2)),
      },
    );
    final loc = res.headers['location'] ?? res.headers['Location'];
    final id = int.tryParse((loc ?? '').split('/').last);
    if (id != null) return id;
    final body = res.body.trim();
    final asInt = int.tryParse(body);
    if (asInt != null) return asInt;
    try {
      final decoded = jsonDecode(body);
      if (decoded is num) return decoded.toInt();
      if (decoded is Map) {
        for (final k in ['id', 'orderId', 'newOrderId']) {
          final v = decoded[k];
          if (v is num) return v.toInt();
        }
      }
    } catch (_) {}
    throw const ApiException('Order created but id was not returned');
  }

  /// GET /api/order/account/{userId}/all
  Future<List<Order>> getMyOrders() async {
    final userId = await TokenStorage.readUserId();
    if (userId == null || userId.isEmpty) {
      throw const ApiException('Account not found, please log in again (401)',
          statusCode: 401);
    }

    final res = await ApiClient.send(
        'GET', ApiConstants.ordersByAccount(userId),
        allow404: true);
    if (res.statusCode == 404 || res.body.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(res.body);
      final List<dynamic> list = decoded is List
          ? decoded
          : (decoded is Map && decoded['items'] is List)
              ? decoded['items'] as List
              : (decoded is Map && decoded['data'] is List)
                  ? decoded['data'] as List
                  : <dynamic>[];

      return list
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.id.compareTo(a.id)); // newest first
    } on FormatException {
      throw const ApiException('Invalid server response');
    }
  }

  Future<void> updateNotes({required int id, required String notes}) =>
      ApiClient.send('PUT', ApiConstants.orderUpdate(id),
          body: {'notes': notes});

  /// DELETE /api/order/delete/{id}
  Future<void> delete(int orderId) =>
      ApiClient.send('DELETE', ApiConstants.orderDelete(orderId));
}
