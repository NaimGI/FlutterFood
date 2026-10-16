import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/meal.dart';
import '../models/order.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final bool deleting;
  final VoidCallback onDelete;

  const OrderCard({
    super.key,
    required this.order,
    required this.onDelete,
    this.deleting = false,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _expanded = false;

  String _money(double v) => '${Meal.currency}${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final subtitle = [
      if (o.restaurant != null && o.restaurant!.isNotEmpty) o.restaurant!,
      if (o.dateText != null) o.dateText!,
    ].join('  •  ');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .12),
                        shape: BoxShape.circle,
                      ),
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
                                  fontSize: 17, fontWeight: FontWeight.w800)),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          ],
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
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (o.itemsCount != null)
                              Text(
                                '${o.itemsCount} '
                                '${o.itemsCount == 1 ? 'item' : 'items'}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                            AnimatedRotation(
                              turns: _expanded ? .5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(Icons.keyboard_arrow_down,
                                  size: 20, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _expanded
                      ? _buildDetails(o)
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(Order o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 26),
        if (o.positions.isNotEmpty) ...[
          const Text('Items',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          ...o.positions.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Text('${p.quantity}×',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(p.name)),
                  if (p.price > 0)
                    Text(_money(p.lineTotal),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (o.notes.isNotEmpty) ...[
          const Text('Note',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(o.notes),
          ),
          const SizedBox(height: 10),
        ],
        if (o.positions.isEmpty && o.notes.isEmpty)
          const Text('No more details for this order',
              style: TextStyle(color: Colors.grey)),
        Row(
          children: [
            if (o.cartId != null)
              Text('Cart #${o.cartId}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.deleting ? null : widget.onDelete,
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              icon: widget.deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, size: 20),
              label: const Text('Delete order'),
            ),
          ],
        ),
      ],
    );
  }
}