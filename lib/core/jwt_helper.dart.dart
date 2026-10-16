import 'dart:convert';

class JwtHelper {
  static const _idKeys = [
    'nameid',
    'sub',
    'id',
    'userId',
    'accountId',
    'uid',
  ];

  static Map<String, dynamic>? decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload);
      return map is Map<String, dynamic> ? map : null;
    } catch (_) {
      return null;
    }
  }

  static String? userId(String token) {
    final claims = decode(token);
    if (claims == null) return null;
    for (final entry in claims.entries) {
      if (entry.key.toLowerCase().endsWith('nameidentifier') &&
          '${entry.value}'.isNotEmpty) {
        return '${entry.value}';
      }
    }

    for (final key in _idKeys) {
      final v = claims[key];
      if (v != null && '$v'.isNotEmpty) return '$v';
    }
    return null;
  }
}