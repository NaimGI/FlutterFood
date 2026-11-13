import 'dart:convert';

import '../core/api_constants.dart';
import '../models/account_profile.dart';
import 'api_client.dart';
import 'api_exception.dart';

class ProfileService {
  Future<AccountProfile> getProfile() async {
    final response = await ApiClient.send('GET', ApiConstants.profile);
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Invalid profile response');
    }
    return AccountProfile.fromJson(decoded);
  }

  Future<AccountProfile> updateLogin(String login) async {
    final response = await ApiClient.send(
      'PUT',
      ApiConstants.profile,
      body: {'login': login},
    );
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Invalid profile response');
    }
    return AccountProfile.fromJson(decoded);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.send(
      'PUT',
      ApiConstants.changePassword,
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
