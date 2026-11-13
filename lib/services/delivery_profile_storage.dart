import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/delivery_profile.dart';

class DeliveryProfileStorage {
  static const _key = 'delivery_profile';
  static const _storage = FlutterSecureStorage();

  static Future<DeliveryProfile?> read() async {
    final value = await _storage.read(key: _key);
    if (value == null || value.isEmpty) return null;
    try { return DeliveryProfile.fromJson(jsonDecode(value) as Map<String, dynamic>); } catch (_) { return null; }
  }

  static Future<void> save(DeliveryProfile value) => _storage.write(key: _key, value: jsonEncode(value.toJson()));
  static Future<void> clear() => _storage.delete(key: _key);
}
