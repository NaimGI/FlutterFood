import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/meal.dart';
import '../models/order.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../services/meal_service.dart';
import '../services/order_service.dart';
import '../widgets/app_sheet.dart';
import '../widgets/app_snackbar.dart';
import 'login_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _service = OrderService();
  final _meals = MealService();

  List<Order> _orders = [];
  Map<int, List<MealItem>> _itemsByOrder = {};
  bool _loading = true;
  Object? _error;
  final Set<int> _busy = {};

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
      final list = await _service.getMyOrders();
      final map = <int, List<MealItem>>{};
      await Future.wait(list.map((o) async {
        try {
          map[o.id] = await _meals.getByOrder(o.id);
        } catch (_) {
          map[o.id] = [];
        }
      }));
      if (!mounted) return;
      setState(() {
        _orders = list;
        _itemsByOrder = map;
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

  Future<void> _delete(Order order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete order?'),
        content: Text('Order #${order.id} will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy.add(order.id));
    try {
      await _service.delete(order.id);
      if (!mounted) return;
      setState(() {
        _orders.removeWhere((o) => o.id == order.id);
        _itemsByOrder.remove(order.id);
      });
      AppSnackbar.success(context, 'Order #${order.id} deleted');
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await _goLogin();
        return;
      }
      AppSnackbar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  Future<void> _editNotes(Order order) async {
    final ctrl = TextEditingController(text: order.notes);
    final saved = await showAppSheet<bool>(
      context: context,
      title: 'Edit note — Order #${order.id}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
              controller: ctrl,
              maxLines: 3,
              minLines: 2,
              maxLength: 200,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'e.g. no onions',
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26))),
              child: const Text('Save',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    setState(() => _busy.add(order.id));
    try {
      await _service.updateNotes(id: order.id, notes: ctrl.text.trim());
      await _load();
      if (!mounted) return;
      AppSnackbar.success(context, 'Note updated');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  String _money(double v) => '${Meal.currency}${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('My Orders',
              style: TextStyle(fontWeight: FontWeight.w800))),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      final isExpired =
          _error is ApiException && (_error as ApiException).statusCode == 401;
      final message = _error is ApiException
          ? (_error as ApiException).message
          : 'Unexpected error';
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  foregroundColor: Colors.white),
              child: Text(isExpired ? 'Log in again' : 'Retry'),
            ),
          ],
        ),
      );
    }
    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 90),
            Icon(Icons.receipt_long_outlined,
                size: 72, color: Colors.grey),
            SizedBox(height: 14),
            Center(
                child: Text('No orders yet',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800))),
            SizedBox(height: 6),
            Center(
                child: Text('Orders you place will show up here',
                    style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }
    final spent = _orders.fold<double>(0, (s, o) => s + o.totalPrice);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          if (i == 0) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFF9A4D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Column(children: [
                    Text('${_orders.length}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const Text('Orders',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ])),
                  Container(width: 1, height: 36, color: Colors.white38),
                  Expanded(
                      child: Column(children: [
                    Text(_money(spent),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    const Text('Total spent',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ])),
                ],
              ),
            );
          }
          final order = _orders[i - 1];
          final items = _itemsByOrder[order.id] ?? [];
          final busy = _busy.contains(order.id);
          return _OrderTile(
            order: order,
            items: items,
            busy: busy,
            onDelete: () => _delete(order),
            onEdit: () => _editNotes(order),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatefulWidget {
  final Order order;
  final List<MealItem> items;
  final bool busy;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _OrderTile(
      {required this.order,
      required this.items,
      required this.busy,
      required this.onDelete,
      required this.onEdit});

  @override
  State<_OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<_OrderTile> {
  bool _expanded = false;

  String _money(double v) => '${Meal.currency}${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final count =
        widget.items.fold<int>(0, (s, e) => s + e.quantity);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .06),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .12),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${o.id}',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800)),
                        if (o.restaurant != null &&
                            o.restaurant!.isNotEmpty)
                          Text(o.restaurant!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_money(o.totalPrice),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      Text('$count items',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Icon(_expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                ],
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 26),
              ...widget.items.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Text('${p.quantity}×',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(p.name)),
                        Text(_money(p.lineTotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
              if (o.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.fieldFill,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(o.notes),
                ),
              ],
              if (o.cartId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Cart #${o.cartId}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.busy ? null : widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit note'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: widget.busy ? null : widget.onDelete,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
