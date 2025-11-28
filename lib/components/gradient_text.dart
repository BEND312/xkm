import 'package:flutter/material.dart';

class GradientText extends StatelessWidget {
  const GradientText(this.text,
      {super.key, required this.gradient, this.style, this.shadows});

  final String text;
  final Gradient gradient;
  final TextStyle? style;
  final List<Shadow>? shadows;

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => gradient
            .createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
        child: Padding(
            padding: const EdgeInsets.all(0), child: Text(text, style: style)),
      );
}
