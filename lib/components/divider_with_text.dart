import 'package:flutter/material.dart';

class DividerWithText extends StatelessWidget {
  const DividerWithText(
      {super.key,
      required this.child,
      this.gap = 8.0,
      this.crossAxisAlignment = CrossAxisAlignment.center,
      this.color})
      : assert(crossAxisAlignment == CrossAxisAlignment.start ||
            crossAxisAlignment == CrossAxisAlignment.center ||
            crossAxisAlignment == CrossAxisAlignment.end);

  final Widget child;
  final double gap;
  final CrossAxisAlignment crossAxisAlignment;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final g = SizedBox(width: gap);
    final d = Expanded(child: Divider(color: color));
    final s = SizedBox(width: 12.0, child: Divider(color: color));
    return Row(
        children: switch (crossAxisAlignment) {
      CrossAxisAlignment.start => [s, g, child, g, d],
      CrossAxisAlignment.center => [d, g, child, g, d],
      CrossAxisAlignment.end => [d, g, child, g, s],
      _ => []
    });
  }
}
