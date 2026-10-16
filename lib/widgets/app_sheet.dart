import 'package:flutter/material.dart';

/// Reusable bottom-sheet shell so action buttons are never hidden
/// behind the Android nav bar / iPhone home indicator / keyboard.
///
/// Usage:
/// ```dart
/// final changed = await showAppSheet<bool>(
///   context: context,
///   title: 'Add meal',
///   child: MyForm(),
/// );
/// ```
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.92,
    ),
    builder: (_) => AppSheet(title: title, child: child),
  );
}

class AppSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const AppSheet({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    // viewInsets = keyboard, viewPadding = system nav bar / notch.
    final insets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.viewPaddingOf(context);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          // Keyboard height + nav-bar height + breathing room.
          bottom: insets.bottom + padding.bottom + 16,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
