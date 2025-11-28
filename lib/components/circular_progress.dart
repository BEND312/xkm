import 'package:flutter/material.dart';
import 'package:swustmeow/data/m_theme.dart';

class CircularProgress extends StatelessWidget {
  const CircularProgress({
    super.key,
    required this.maxValue,
    required this.value,
    required this.size,
    this.strokeWidth,
    this.backgroundColor,
    this.color,
    this.child,
  }) : assert(maxValue > 0 && value >= 0);

  final double maxValue;
  final double value;
  final double size;
  final double? strokeWidth;
  final Color? backgroundColor;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    double progress = (value / maxValue).clamp(0.0, 1.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color ?? MTheme.primary2),
            strokeWidth: strokeWidth ?? 10,
          ),
        ),
        if (child != null) child!
      ],
    );
  }
}
