import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/api_constants.dart';
import '../models/restaurant.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class RestaurantService {
  /// GET api/restaurant/all — always fresh, bypasses any HTTP cache.
  Future<List<Restaurant>> getAll({bool bustCache = true}) async {
    final token = await TokenStorage.read();
    if (token == null || token.isEmpty) {
      throw const ApiException('Session expired (401)', statusCode: 401);
    }

    try {
      var url = ApiConstants.restaurants;
      if (bustCache) {
        url += '?t=${DateTime.now().millisecondsSinceEpoch}';
      }
      debugPrint('➡️ GET $url');

      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('⬅️ ${res.statusCode}: ${res.body}');

      if (res.statusCode == 401) {
        throw const ApiException('Session expired (401)', statusCode: 401);
      }
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException('Failed to load restaurants (${res.statusCode})',
            statusCode: res.statusCode);
      }

      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
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

  /// POST api/restaurant/create {name, category}
  Future<void> create({required String name, required String category}) async {
    await ApiClient.send(
      'POST',
      ApiConstants.restaurantCreate,
      body: {'name': name, 'category': category},
    );
  }

  /// PUT api/restaurant/update/{id} {name, category}
  Future<void> update(
      {required int id, required String name, required String category}) async {
    await ApiClient.send(
      'PUT',
      ApiConstants.restaurantUpdate(id),
      body: {'name': name, 'category': category},
    );
  }

  /// DELETE api/restaurant/delete/{id}
  Future<void> delete(int id) async {
    await ApiClient.send('DELETE', ApiConstants.restaurantDelete(id));
  }
}