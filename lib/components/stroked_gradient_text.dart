import 'package:flutter/material.dart';

import 'gradient_text.dart';

class StrokedGradientText extends StatelessWidget {
  const StrokedGradientText(this.text,
      {super.key,
      required this.gradient,
      required this.strokeWidth,
      this.style,
      this.shadows});

  final String text;
  final Gradient gradient;
  final double strokeWidth;
  final TextStyle? style;
  final List<Shadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final foreground = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final strokeStyle = style == null
        ? TextStyle(foreground: foreground)
        : style!.copyWith(foreground: foreground);
    return Stack(
      children: [
        GradientText(
          text,
          style: strokeStyle,
          gradient: gradient,
        ),
        GradientText(
          text,
          style: style?.copyWith(shadows: shadows),
          gradient: gradient,
        )
      ],
    );
  }
}
