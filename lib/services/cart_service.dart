import 'dart:convert';

import '../core/api_constants.dart';
import '../models/cart.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'token_storage.dart';

class CartService {
  /// Carts of the logged-in user: /api/cart/account/{userId}
  Future<CartPage> getMyCarts() async {
    final userId = await TokenStorage.readUserId();
    if (userId == null || userId.isEmpty) {
      throw const ApiException('Account not found, please log in again (401)',
          statusCode: 401);
    }

    final res = await ApiClient.send(
        'GET', ApiConstants.cartByAccount(userId),
        allow404: true);
    if (res.statusCode == 404 || res.body.trim().isEmpty) {
      return const CartPage.empty();
    }

    final decoded = jsonDecode(res.body);
    if (decoded is List) return CartPage.fromList(decoded);
    if (decoded is Map<String, dynamic>) {
      if (decoded['items'] is List) return CartPage.fromJson(decoded);
      if (decoded.containsKey('totalCartPrice')) {
        return CartPage.fromList([decoded]);
      }
    }
    throw const ApiException('Invalid server response');
  }

  /// POST api/cart/create — returns the new cart id.
  /// Backend answers 200 { newCartId: n }.
  Future<int> createCart({
    required int restaurantId,
    required int organizationId,
    String phoneNumber = '-',
    String bankAccountNumber = '-',
    String note = '',
    String country = '-',
    String city = '-',
    String street = '-',
    String building = '-',
    String? premises,
    double minPrice = 0,
    double deliveryPrice = 0,
    double freeDeliveryMinPrice = 0,
  }) async {
    final accountId = int.tryParse(await TokenStorage.readUserId() ?? '');
    if (accountId == null) {
      throw const ApiException(
          'Account not found, please log in again (401)',
          statusCode: 401);
    }

    final res = await ApiClient.send(
      'POST',
      ApiConstants.cartCreate,
      body: {
        'minPrice': minPrice,
        'deliveryPrice': deliveryPrice,
        'freeDeliveryMinPrice': freeDeliveryMinPrice,
        'phoneNumber': phoneNumber.isEmpty ? '-' : phoneNumber,
        'bankAccountNumber':
            bankAccountNumber.isEmpty ? '-' : bankAccountNumber,
        'note': note,
        'country': country.isEmpty ? '-' : country,
        'city': city.isEmpty ? '-' : city,
        'street': street.isEmpty ? '-' : street,
        'building': building.isEmpty ? '-' : building,
        if (premises != null && premises.isNotEmpty) 'premises': premises,
        'organizationId': organizationId,
        'restaurantId': restaurantId,
        'accountId': accountId,
      },
    );
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        final v = decoded['newCartId'] ?? decoded['id'] ?? decoded['cartId'];
        if (v is num) return v.toInt();
      } else if (decoded is num) {
        return decoded.toInt();
      }
    } catch (_) {}
    throw const ApiException('Cart created but id was not returned');
  }

  /// DELETE api/cart/delete/{id}
  Future<void> deleteCart(int cartId) =>
      ApiClient.send('DELETE', ApiConstants.cartDelete(cartId));
}
