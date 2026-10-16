import 'package:flutter/material.dart';

/// Small responsive helpers so the app works on phones, tablets and desktop.
class Responsive {
  /// Max content width for forms / lists. Centers on tablets & desktop.
  static const double maxFormWidth = 640;
  static const double maxAuthWidth = 440;

  /// Side padding that grows a bit on wide screens.
  static EdgeInsets pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = w < 360 ? 12.0 : 16.0;
    return EdgeInsets.fromLTRB(h, 12, h, 0);
  }

  /// 2 columns on phones, 3 on small tablets, 4 on desktop.
  static int gridCount(BuildContext context, {int phone = 2}) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1100) return phone + 2;
    if (w >= 700) return phone + 1;
    return phone;
  }

  /// SliverAppBar height that never eats a small screen.
  static double headerHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return h < 650 ? 180.0 : 230.0;
  }
}

/// Centers [child] and caps its width — full width on phones,
/// centered column on tablets / desktop.
class MaxWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const MaxWidth(
      {super.key, required this.child, this.maxWidth = Responsive.maxFormWidth});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Two fields side-by-side on wide screens, stacked on narrow phones.
class ResponsiveTwoCol extends StatelessWidget {
  final Widget first;
  final Widget second;
  final double breakpoint;

  const ResponsiveTwoCol(
      {super.key,
      required this.first,
      required this.second,
      this.breakpoint = 380});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        if (c.maxWidth < breakpoint) {
          return Column(
            children: [first, const SizedBox(height: 12), second],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 12),
            Expanded(child: second),
          ],
        );
      },
    );
  }
}
