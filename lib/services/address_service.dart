import 'dart:convert';

import '../core/api_constants.dart';
import '../models/saved_address.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AddressService {
  Future<List<SavedAddress>> getMine() async {
    final response = await ApiClient.send('GET', ApiConstants.myAddresses);
    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const ApiException('Invalid addresses response');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SavedAddress.fromJson)
        .toList();
  }

  Future<SavedAddress> create(SavedAddress address) =>
      _save(ApiConstants.addresses, 'POST', address);

  Future<SavedAddress> update(SavedAddress address) =>
      _save(ApiConstants.address(address.id), 'PUT', address);

  Future<void> setDefault(int addressId) async {
    await ApiClient.send('PUT', ApiConstants.addressDefault(addressId));
  }

  Future<void> delete(int addressId) async {
    await ApiClient.send('DELETE', ApiConstants.address(addressId));
  }

  Future<SavedAddress> _save(
    String url,
    String method,
    SavedAddress address,
  ) async {
    final response = await ApiClient.send(method, url, body: address.toJson());
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Invalid address response');
    }
    return SavedAddress.fromJson(decoded);
  }
}
