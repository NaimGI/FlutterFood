import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_app/core/jwt_helper.dart.dart';

import '../core/api_constants.dart';
import '../models/auth_request.dart';
import '../models/auth_response.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class AuthService {
  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

Future<AuthResponse> login(AuthRequest request) async {
  final response = await _post(ApiConstants.login, request);
  final token = response.token;
  if (token == null || token.isEmpty) {
    debugPrint('Login response had no token: ${response.raw}');
    throw const ApiException('Token not found in login response');
  }

  await TokenStorage.save(token);
  await TokenStorage.saveUsername(request.login);

  final userId = _extractUserId(response, token);
  if (userId != null) {
    await TokenStorage.saveUserId(userId);
  } else {
    debugPrint('No user id found. Login: ${response.raw} '
        'JWT: ${JwtHelper.decode(token)}');
  }
  return response;
}

String? _extractUserId(AuthResponse response, String token) {
  final raw = response.raw;
  final user = raw['user'] is Map ? raw['user'] as Map : null;

  final fromBody = raw['id'] ??
      raw['userId'] ??
      raw['accountId'] ??
      user?['id'];

  if (fromBody != null && '$fromBody'.isNotEmpty) return '$fromBody';
  return JwtHelper.userId(token);
}

  Future<AuthResponse> register(AuthRequest request) =>
      _post(ApiConstants.register, request);

  Future<void> logout() => TokenStorage.clear();

  Future<AuthResponse> _post(String url, AuthRequest request) async {
    try {
      final body = jsonEncode(request.toJson());
      debugPrint('➡️ POST $url');

      final res = await http
          .post(Uri.parse(url), headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));

      debugPrint('⬅️ ${res.statusCode}: ${res.body}');

      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.trim().isEmpty) return const AuthResponse();
        try {
          final decoded = jsonDecode(res.body);
          return decoded is Map<String, dynamic>
              ? AuthResponse.fromJson(decoded)
              : AuthResponse(raw: {'data': decoded});
        } on FormatException {
          // API returned a plain token string, not JSON
          return AuthResponse(token: res.body.trim().replaceAll('"', ''));
        }
      }

      throw ApiException(_errorMessage(res), statusCode: res.statusCode);
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

  String _errorMessage(http.Response res) {
    String? msg;
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        msg = (body['message'] ?? body['title'] ?? body['error'])?.toString();
      } else if (body is String) {
        msg = body;
      }
    } catch (_) {}

    if (msg == null || msg.isEmpty) {
      msg = res.statusCode == 401 ? 'Invalid credentials' : 'Request failed';
    }
    return '$msg (${res.statusCode})';
  }
}