import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/meal.dart';
import '../models/restaurant.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/meal_service.dart';
import '../services/restaurant_service.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class ManageMealScreen extends StatefulWidget {
  const ManageMealScreen({super.key});

  @override
  State<ManageMealScreen> createState() => ManageMealScreenState();
}

class ManageMealScreenState extends State<ManageMealScreen> {
  final _restaurants = RestaurantService();
  final _meals = MealService();

  List<Restaurant> _all = [];
  int? _restaurantId;
  List<Meal>? _items;
  bool _loading = true;
  Object? _error;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> refresh() => _loadMeals();

  Future<void> _init() async {
    try {
      final all = await _restaurants.getAll();
      if (!mounted) return;
      setState(() {
        _all = all;
        _restaurantId = all.isNotEmpty ? all.first.id : null;
      });
      await _loadMeals();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMeals() async {
    if (_restaurantId == null) {
      setState(() {
        _items = [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _meals.getByRestaurant(_restaurantId!);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.statusCode == 401) {
        await AuthService().logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false);
        return;
      }
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _openForm({Meal? existing}) async {
    if (_restaurantId == null) return;
    final changed = await showAppSheet<bool>(
      context: context,
      title: existing != null ? 'Edit meal' : 'Add meal',
      child: _MealFormBody(
          restaurantId: _restaurantId!, meal: existing),
    );
    if (changed == true) _loadMeals();
  }

  Future<void> _delete(Meal m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${m.name}"?'),
        content: const Text('This meal will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy.add(m.id));
    try {
      await _meals.delete(m.id);
      if (!mounted) return;
      AppSnackbar.success(context, 'Meal deleted');
      await _loadMeals();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(
          context, e is ApiException ? e.message : 'Unexpected error');
    } finally {
      if (mounted) setState(() => _busy.remove(m.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Manage Meals',
              style: TextStyle(fontWeight: FontWeight.w800))),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              initialValue: _restaurantId,
              decoration: const InputDecoration(
                labelText: 'Restaurant',
                border: OutlineInputBorder(),
              ),
              items: _all
                  .map((r) => DropdownMenuItem(
                      value: r.id,
                      child: Text('${r.name} (${r.category})')))
                  .toList(),
              onChanged: (v) {
                setState(() => _restaurantId = v);
                _loadMeals();
              },
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      final msg = _error is ApiException
          ? (_error as ApiException).message
          : 'Unexpected error';
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 44, color: AppColors.error),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMeals,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final items = _items ?? [];
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadMeals,
        child: ListView(children: const [
          SizedBox(height: 80),
          Center(child: Text('No meals yet — tap + to add one')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMeals,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final m = items[i];
          final busy = _busy.contains(m.id);
          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.network(m.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: AppColors.fieldFill,
                          child: const Icon(Icons.fastfood,
                              color: Colors.grey))),
                ),
              ),
              title: Text(m.name,
                  style:
                      const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(
                  '${m.priceText}${m.description?.isNotEmpty == true ? ' • ${m.description}' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              trailing: busy
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Colors.blueGrey),
                            onPressed: () =>
                                _openForm(existing: m)),
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.error),
                            onPressed: () => _delete(m)),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _MealFormBody extends StatefulWidget {
  final int restaurantId;
  final Meal? meal;

  const _MealFormBody({required this.restaurantId, this.meal});

  @override
  State<_MealFormBody> createState() => _MealFormBodyState();
}

class _MealFormBodyState extends State<_MealFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imgCtrl;
  bool _loading = false;

  bool get _isEdit => widget.meal != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.meal?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.meal?.description ?? '');
    _priceCtrl = TextEditingController(
        text: widget.meal != null ? '${widget.meal!.price}' : '');
    _imgCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imgCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final name = _nameCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      final price =
          double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.')) ??
              -1;
      final img = _imgCtrl.text.trim();
      if (_isEdit) {
        await MealService().update(
            id: widget.meal!.id,
            name: name,
            description: desc,
            price: price,
            imageUrl: img.isEmpty ? null : img);
      } else {
        await MealService().create(
            name: name,
            description: desc.isEmpty ? '-' : desc,
            price: price,
            imageUrl: img.isEmpty ? null : img,
            restaurantId: widget.restaurantId);
      }
      if (!mounted) return;
      AppSnackbar.success(context,
          _isEdit ? 'Meal updated' : 'Meal added');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context,
          e is ApiException ? e.message : 'Unexpected error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
              label: 'Name',
              hint: 'e.g. Margherita',
              controller: _nameCtrl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null),
          const SizedBox(height: 12),
          AppTextField(
              label: 'Description',
              hint: 'e.g. Tomato, mozzarella',
              controller: _descCtrl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty)
                      ? 'Description is required'
                      : null),
          const SizedBox(height: 12),
          AppTextField(
              label: 'Price',
              hint: 'e.g. 9.99',
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              validator: (v) {
                final p = double.tryParse(
                    (v ?? '').trim().replaceAll(',', '.'));
                if (p == null || p <= 0) return 'Enter a valid price';
                return null;
              }),
          const SizedBox(height: 12),
          AppTextField(
              label: 'Image URL (optional)',
              hint: 'https://…',
              controller: _imgCtrl,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done),
          const SizedBox(height: 20),
          PrimaryButton(
              text: _isEdit ? 'Save changes' : 'Add meal',
              loading: _loading,
              onPressed: _submit),
          // Extra room so the button never touches the nav bar.
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
