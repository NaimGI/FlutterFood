import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/restaurant.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/cart_badge.dart';
import '../services/cart_draft.dart';
import '../services/restaurant_service.dart';
import '../widgets/restaurant_card.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'restaurant_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    CartBadge.refresh();
  }

  Future<void> _logout() async {
    CartDraft.instance.clear();
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _cartIcon() => ValueListenableBuilder<List<CartDraftItem>>(
        valueListenable: CartDraft.instance,
        builder: (_, items, __) {
          final n =
              items.fold<int>(0, (s, e) => s + e.quantity);
          return Badge(
            isLabelVisible: n > 0,
            label: Text(n > 99 ? '99+' : '$n'),
            child: const Icon(Icons.shopping_cart_outlined),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _RestaurantsTab(onSessionExpired: _logout),
      _index == 1 ? const OrdersScreen() : const SizedBox.shrink(),
      _index == 2 ? const CartScreen() : const SizedBox.shrink(),
      _index == 3 ? const ProfileScreen() : const SizedBox.shrink(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: pages)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.black54,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: _cartIcon(), label: 'Cart'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _RestaurantsTab extends StatefulWidget {
  final VoidCallback onSessionExpired;
  const _RestaurantsTab({required this.onSessionExpired});

  @override
  State<_RestaurantsTab> createState() => _RestaurantsTabState();
}

class _RestaurantsTabState extends State<_RestaurantsTab> {
  final _service = RestaurantService();
  final _searchCtrl = TextEditingController();
  List<Restaurant>? _items;
  bool _loading = true;
  Object? _error;
  bool _searching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getAll(bustCache: true);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _query = '';
        _searchCtrl.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaxWidth(
      child: Padding(
        padding: Responsive.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            if (_searching) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search restaurants or categories',
                  filled: true,
                  fillColor: AppColors.fieldFill,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('Explore Restaurants',
                style: TextStyle(
                    fontSize: MediaQuery.sizeOf(context).width < 360
                        ? 24
                        : 28,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text('Choose a restaurant to see its menu',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 14),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError(_error!);
    final all = _items ?? [];
    final items = _query.isEmpty
        ? all
        : all
            .where((r) =>
                r.name.toLowerCase().contains(_query) ||
                r.category.toLowerCase().contains(_query))
            .toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: items.isEmpty
          ? ListView(children: const [
              SizedBox(height: 80),
              Center(child: Text('No restaurants found')),
            ])
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Responsive.gridCount(context),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio:
                    MediaQuery.sizeOf(context).width < 360 ? 0.68 : 0.72,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => RestaurantCard(
                restaurant: items[i],
                onTap: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailScreen(
                            restaurant: items[i]),
                      ),
                    )
                    .then((_) => CartBadge.refresh()),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.location_on_outlined,
              color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deliver to:',
                  style: TextStyle(color: Colors.black54, fontSize: 13)),
              Text('123 Tech Ave',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        ValueListenableBuilder<List<CartDraftItem>>(
          valueListenable: CartDraft.instance,
          builder: (_, items, __) {
            final n =
                items.fold<int>(0, (s, e) => s + e.quantity);
            return Badge(
              isLabelVisible: n > 0,
              label: Text('$n'),
              child: InkWell(
                onTap: _toggleSearch,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(_searching ? Icons.close : Icons.search),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildError(Object error) {
    final isExpired = error is ApiException && error.statusCode == 401;
    final message = error is ApiException ? error.message : 'Unexpected error';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 44, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: isExpired ? widget.onSessionExpired : _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(isExpired ? 'Log in again' : 'Retry'),
          ),
        ],
      ),
    );
  }
}
