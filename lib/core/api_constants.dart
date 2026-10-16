import 'dart:io';

class ApiConstants {
  // Android emulator cannot reach the PC's "localhost" -> use 10.0.2.2.
  // Windows desktop / iOS simulator can use localhost.
  static String get host {
    if (Platform.isAndroid) return 'https://10.66.206.8:7157';
    return 'https://localhost:7157';
  }

  static String get register => '$host/api/account/register';
  static String get login => '$host/api/account/login';

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
  static String mealAddToOrder(int orderId) => '$host/api/meal/addMeal/$orderId';
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
  static String ordersByAccount(String accountId) =>
      '$host/api/order/account/$accountId/all';

  // Organization
  static String get organizations => '$host/api/organization/all';
  static String get organizationCreate => '$host/api/organization/create';
  static String organizationDelete(int id) =>
      '$host/api/organization/delete/$id';
}
