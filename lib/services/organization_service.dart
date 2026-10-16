import 'dart:convert';

import '../core/api_constants.dart';
import 'api_client.dart';

class Organization {
  final int id;
  final String name;

  const Organization({required this.id, required this.name});

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: (json['id'] as num).toInt(),
        name: (json['name'] ?? '').toString(),
      );
}

class OrganizationService {
  Future<List<Organization>> getAll() async {
    final res = await ApiClient.send('GET', ApiConstants.organizations,
        allow404: true);
    if (res.statusCode == 404 || res.body.trim().isEmpty) return [];
    final decoded = jsonDecode(res.body);
    final List<dynamic> list = decoded is List
        ? decoded
        : (decoded is Map && decoded['items'] is List)
            ? decoded['items'] as List
            : <dynamic>[];
    return list
        .map((e) => Organization.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(String name) => ApiClient.send(
      'POST', ApiConstants.organizationCreate,
      body: {'name': name});

  Future<void> delete(int id) =>
      ApiClient.send('DELETE', ApiConstants.organizationDelete(id));
}
