import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/meal.dart';
import '../models/restaurant.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/cart_draft.dart';
import '../services/meal_service.dart';
import '../widgets/app_snackbar.dart';
import 'cart_screen.dart';
import 'login_screen.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final _service = MealService();
  List<Meal>? _meals;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meals = await _service.getByRestaurant(widget.restaurant.id);
      if (!mounted) return;
      setState(() {
        _meals = meals;
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

  Future<void> _goLogin() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _add(Meal meal) {
    final draft = CartDraft.instance;
    if (!draft.canAdd(widget.restaurant)) {
      AppSnackbar.error(context,
          'Your basket has items from another restaurant. Clear it first.');
      return;
    }
    draft.add(widget.restaurant, meal);
    AppSnackbar.success(context, '${meal.name} added to basket');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restaurant;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: Responsive.headerHeight(context),
              backgroundColor: Colors.white,
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.white70,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  r.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.fieldFill,
                    child: const Icon(Icons.restaurant,
                        size: 60, color: Colors.grey),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name,
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(r.category,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 20),
                    const Text('Menu',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            _buildMenu(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBasketBar(),
    );
  }

  Widget _buildMenu() {
    if (_loading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      final isExpired =
          _error is ApiException && (_error as ApiException).statusCode == 401;
      final message =
          _error is ApiException ? (_error as ApiException).message : 'Unexpected error';
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
          child: Column(
            children: [
              const Icon(Icons.error_outline,
                  size: 44, color: AppColors.error),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isExpired ? _goLogin : _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(isExpired ? 'Log in again' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final meals = _meals ?? [];
    if (meals.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 60),
          child: Center(child: Text('No meals available yet')),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList.separated(
        itemCount: meals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _MealRow(
          meal: meals[i],
          restaurant: widget.restaurant,
          onChanged: () => setState(() {}),
          onAdd: () => _add(meals[i]),
        ),
      ),
    );
  }

  Widget _buildBasketBar() {
    return ValueListenableBuilder<List<CartDraftItem>>(
      valueListenable: CartDraft.instance,
      builder: (_, items, __) {
        if (items.isEmpty) return const SizedBox.shrink();
        final count = CartDraft.instance.count;
        final total = CartDraft.instance.itemsTotal;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                          builder: (_) => const CartScreen()),
                    )
                    .then((_) => setState(() {})),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: Text(
                  'View basket • $count items • \$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MealRow extends StatelessWidget {
  final Meal meal;
  final Restaurant restaurant;
  final VoidCallback onChanged;
  final VoidCallback onAdd;

  const _MealRow(
      {required this.meal,
      required this.restaurant,
      required this.onChanged,
      required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CartDraftItem>>(
      valueListenable: CartDraft.instance,
      builder: (_, items, __) {
        final qty = CartDraft.instance.quantityOf(meal.id);
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: Image.network(
                    meal.imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.fieldFill,
                      child:
                          const Icon(Icons.fastfood, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    if (meal.description != null &&
                        meal.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(meal.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    Text(meal.priceText,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (qty == 0)
                InkWell(
                  onTap: () {
                    onAdd();
                    onChanged();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () {
                          CartDraft.instance
                              .setQuantity(meal.id, qty - 1);
                          onChanged();
                        },
                      ),
                      Text('$qty',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800)),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () {
                          CartDraft.instance
                              .add(restaurant, meal);
                          onChanged();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
