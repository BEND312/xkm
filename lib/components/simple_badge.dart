import 'package:flutter/material.dart';

import '../data/m_theme.dart';

class SimpleBadge extends StatelessWidget {
  const SimpleBadge({
    super.key,
    required this.child,
    this.color,
  });

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Baseline(
      baseline: 20,
      baselineType: TextBaseline.alphabetic,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? MTheme.primary1,
          borderRadius: BorderRadius.circular(MTheme.radius),
        ),
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: child,
      ),
    );
  }
}
