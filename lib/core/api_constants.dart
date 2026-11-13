import 'dart:io';

class ApiConstants {
  static const _configuredHost = String.fromEnvironment('API_HOST');

  static String get host {
    if (_configuredHost.isNotEmpty) return _configuredHost;
    // Android emulator cannot reach the PC's "localhost" -> use 10.0.2.2.
    if (Platform.isAndroid) return 'https://10.0.2.2:7157';
    // Windows desktop / iOS simulator can use localhost.
    return 'https://localhost:7157';
  }

  static String get register => '$host/api/account/register';
  static String get login => '$host/api/account/login';
  static String get profile => '$host/api/account/profile';
  static String get changePassword => '$host/api/account/password';

  // Saved delivery locations
  static String get addresses => '$host/api/address';
  static String get myAddresses => '$host/api/address/mine';
  static String address(int id) => '$host/api/address/$id';
  static String addressDefault(int id) => '$host/api/address/$id/default';

  // Restaurant
  static String get restaurants => '$host/api/restaurant/all';
  static String get restaurantCreate => '$host/api/restaurant/create';
  static String restaurantUpdate(int id) => '$host/api/restaurant/update/$id';
  static String restaurantDelete(int id) => '$host/api/restaurant/delete/$id';

  // Meal
  static String get mealCreate => '$host/api/meal/create';
  static String mealUpdate(int id) => '$host/api/meal/update/$id';
  static String mealDelete(int id) => '$host/api/meal/delete/$id';
  static String mealsByRestaurant(int restaurantId) =>
      '$host/api/meal/restaurant/$restaurantId/all';
  static String mealsByOrder(int orderId) => '$host/api/meal/order/$orderId';
  static String mealAddToOrder(int orderId) =>
      '$host/api/meal/addMeal/$orderId';
  static String mealRemoveFromOrder(int orderId) =>
      '$host/api/meal/removeMeal/$orderId';

  // Cart
  static String get cartCreate => '$host/api/cart/create';
  static String cartGet(int id) => '$host/api/cart/get/$id';
  static String cartUpdate(int id) => '$host/api/cart/update/$id';
  static String cartDelete(int id) => '$host/api/cart/delete/$id';
  static String cartByAccount(String accountId) =>
      '$host/api/cart/account/$accountId';

  // Order
  static String get orderCreate => '$host/api/order/create';
  static String orderGet(int id) => '$host/api/order/get/$id';
  static String orderUpdate(int id) => '$host/api/order/update/$id';
  static String orderDelete(int orderId) => '$host/api/order/delete/$orderId';
  static String orderRating(int orderId) => '$host/api/order/$orderId/rating';
  static String orderReport(int orderId) => '$host/api/order/$orderId/report';
  static String get pricingQuote => '$host/api/pricing/quote';
  static String get calorieEstimate => '$host/api/calories/estimate';
  static String ordersByAccount(String accountId) =>
      '$host/api/order/account/$accountId/all';

  // Organization
  static String get organizations => '$host/api/organization/all';
  static String get organizationCreate => '$host/api/organization/create';
  static String organizationDelete(int id) =>
      '$host/api/organization/delete/$id';
}
