import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/responsive.dart';
import '../models/restaurant.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/restaurant_service.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class ManageRestaurantScreen extends StatefulWidget {
  const ManageRestaurantScreen({super.key});

  @override
  State<ManageRestaurantScreen> createState() => ManageRestaurantScreenState();
}

class ManageRestaurantScreenState extends State<ManageRestaurantScreen> {
  final _service = RestaurantService();
  final _searchCtrl = TextEditingController();
  List<Restaurant>? _items;
  bool _loading = true;
  Object? _error;
  String _query = '';
  final Set<int> _deleting = {};

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Public so the parent tab bar can force a fresh load on tab switch.
  Future<void> refresh() => _reload();

  Future<void> _reload() async {
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

  Future<void> _goLogin() async {
    await AuthService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _handleError(Object e) {
    if (e is ApiException && e.statusCode == 401) {
      _goLogin();
      return;
    }
    final msg = e is ApiException ? e.message : 'Unexpected error';
    AppSnackbar.error(context, msg);
  }

  Future<void> _openForm({Restaurant? existing}) async {
    final changed = await showAppSheet<bool>(
      context: context,
      title: existing != null ? 'Edit restaurant' : 'Add restaurant',
      child: _RestaurantFormBody(restaurant: existing),
    );
    if (changed == true) {
      // Clear the search filter so the new/updated item is visible,
      // then await the fresh load before returning.
      _searchCtrl.clear();
      setState(() => _query = '');
      await _reload();
    }
  }

  Future<void> _confirmDelete(Restaurant r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete "${r.name}"?'),
        content: const Text(
            'This will permanently delete the restaurant and its meals.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deleting.add(r.id));
    try {
      await _service.delete(r.id);
      if (!mounted) return;
      AppSnackbar.success(context, 'Restaurant deleted');
      await _reload();
    } catch (e) {
      if (!mounted) return;
      _handleError(e);
    } finally {
      if (mounted) setState(() => _deleting.remove(r.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Restaurants',
            style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: MaxWidth(
          child: Padding(
            padding: Responsive.pagePadding(context),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
              onChanged: (v) =>
                  setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search restaurants or categories',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.fieldFill,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items == null) return _buildError(_error!);
    final all = _items ?? [];
    final items = _query.isEmpty
        ? all
        : all
            .where((r) =>
                r.name.toLowerCase().contains(_query) ||
                r.category.toLowerCase().contains(_query))
            .toList();
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(children: const [
          SizedBox(height: 80),
          Center(child: Text('No restaurants found')),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: items.length,
        separatorBuilder: (context, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = items[i];
          final busy = _deleting.contains(r.id);
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: .12),
                              child: Text(
                                r.name.isNotEmpty
                                    ? r.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary),
                              ),
                            ),
                            title: Text(r.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '#${r.id} • ${r.category.isEmpty ? 'No category' : r.category}'),
                            trailing: busy
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            color: Colors.blueGrey),
                                        tooltip: 'Edit',
                                        onPressed: () =>
                                            _openForm(existing: r),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            color: AppColors.error),
                                        tooltip: 'Delete',
                                        onPressed: () => _confirmDelete(r),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
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
            onPressed: isExpired ? _goLogin : _reload,
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

class _RestaurantFormBody extends StatefulWidget {
  final Restaurant? restaurant;
  const _RestaurantFormBody({this.restaurant});

  @override
  State<_RestaurantFormBody> createState() => _RestaurantFormBodyState();
}

class _RestaurantFormBodyState extends State<_RestaurantFormBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _categoryCtrl;
  bool _loading = false;

  bool get _isEdit => widget.restaurant != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.restaurant?.name ?? '');
    _categoryCtrl =
        TextEditingController(text: widget.restaurant?.category ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final name = _nameCtrl.text.trim();
      final category = _categoryCtrl.text.trim();
      if (_isEdit) {
        await RestaurantService()
            .update(id: widget.restaurant!.id, name: name, category: category);
      } else {
        await RestaurantService().create(name: name, category: category);
      }
      if (!mounted) return;
      AppSnackbar.success(
          context, _isEdit ? 'Restaurant updated' : 'Restaurant added');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'Unexpected error';
      AppSnackbar.error(context, msg);
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
            hint: 'e.g. Pizza House',
            controller: _nameCtrl,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Name is required'
                : null,
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Category',
            hint: 'e.g. Italian',
            controller: _categoryCtrl,
            textInputAction: TextInputAction.done,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Category is required'
                : null,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            text: _isEdit ? 'Save changes' : 'Add restaurant',
            loading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
