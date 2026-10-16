import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'token_storage.dart';

class ApiClient {
  static Future<http.Response> send(
    String method,
    String url, {
    Object? body,
    bool allow404 = false,
  }) async {
    final token = await TokenStorage.read();
    if (token == null || token.isEmpty) {
      throw const ApiException('Session expired (401)', statusCode: 401);
    }

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final uri = Uri.parse(url);
    debugPrint('➡️  ${body ?? ''}');
    final encoded = body == null ? null : jsonEncode(body);

    try {
      debugPrint('➡️ $method $url ${encoded ?? ''}');

      final Future<http.Response> req;
      switch (method) {
        case 'POST':
          req = http.post(uri, headers: headers, body: encoded);
          break;
        case 'PUT':
          req = http.put(uri, headers: headers, body: encoded);
          break;
        case 'PATCH':
          req = http.patch(uri, headers: headers, body: encoded);
          break;
        case 'DELETE':
          req = http.delete(uri, headers: headers, body: encoded);
          break;
        default:
          req = http.get(uri, headers: headers);
      }

      final res = await req.timeout(const Duration(seconds: 15));
      debugPrint('⬅️ ${res.statusCode}: ${res.body}');

      if (res.statusCode == 401) {
        throw const ApiException('Session expired (401)', statusCode: 401);
      }
      if (res.statusCode == 404 && allow404) return res;
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw ApiException(_message(res), statusCode: res.statusCode);
      }
      return res;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException('Cannot reach server');
    } on TimeoutException {
      throw const ApiException('Request timed out');
    } on HandshakeException {
      throw const ApiException('SSL certificate error');
    }
  }

  static String _message(http.Response res) {
    final code = res.statusCode;
    try {
      final b = jsonDecode(res.body);
      if (b is Map) {
        final errors = b['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.entries.first;
          final detail = first.value is List && (first.value as List).isNotEmpty
              ? (first.value as List).first
              : first.value;
          return '${first.key}: $detail ($code)';
        }
        final m = b['message'] ?? b['title'] ?? b['error'];
        if (m != null) return '$m ($code)';
      } else if (b is String && b.isNotEmpty) {
        return '$b ($code)';
      }
    } catch (_) {
      final text = res.body.trim();
      if (text.isNotEmpty && text.length < 120) return '$text ($code)';
    }
    return 'Request failed ($code)';
  }
}