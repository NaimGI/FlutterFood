import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../core/app_images.dart';
import '../core/app_theme.dart';
import '../models/meal.dart';

class CartCard extends StatelessWidget {
  final Cart cart;
  final VoidCallback? onCheckout;

  const CartCard({super.key, required this.cart, this.onCheckout});

  String _money(double v) => '${Meal.currency}${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: Image.network(
                    AppImages.forId(cart.id),
                    fit: BoxFit.cover,
                    cacheWidth: 250,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.fieldFill,
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cart.restaurant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(cart.organization,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _row('Items total', _money(cart.totalCartPrice)),
          const SizedBox(height: 6),
          _row('Delivery',
              cart.freeDelivery ? 'Free' : _money(cart.deliveryFee)),
          const SizedBox(height: 6),
          _row('Total', _money(cart.totalToPay), bold: true),
          const SizedBox(height: 10),
          if (!cart.meetsMinimum)
            _hint('Minimum order ${_money(cart.minPrice)} '
                '(add ${_money(cart.missingForMinimum)} more)',
                AppColors.error)
          else if (!cart.freeDelivery && cart.freeDeliveryMinPrice > 0)
            _hint('Add ${_money(cart.missingForFreeDelivery)} more '
                'for free delivery', Colors.grey)
          else if (cart.freeDelivery)
            _hint('You get free delivery', AppColors.success),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: cart.meetsMinimum ? onCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: .4),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22)),
              ),
              child: const Text('CHECKOUT',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hint(String text, Color color) =>
      Text(text, style: TextStyle(color: color, fontSize: 13));

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 17 : 15,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}