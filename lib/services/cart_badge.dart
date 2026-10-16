import 'package:flutter/foundation.dart';

import 'cart_draft.dart';

/// Shared number shown on the Cart icon of the bottom bar.
/// Now mirrors the local basket (draft) — instant and always correct.
/// Kept under the old name so existing imports keep working.
class CartBadge {
  static ValueNotifier<int> get count => _CountBridge.count;

  /// Syncs the legacy counter from the draft. Safe to call anywhere.
  static Future<void> refresh() async {
    _CountBridge.sync();
  }
}

class _CountBridge {
  static final ValueNotifier<int> count = ValueNotifier<int>(0);
  static bool _wired = false;

  static void sync() {
    if (!_wired) {
      _wired = true;
      CartDraft.instance.addListener(() {
        count.value = CartDraft.instance.count;
      });
    }
    count.value = CartDraft.instance.count;
    debugPrint('Cart badge: ${count.value}');
  }
}
