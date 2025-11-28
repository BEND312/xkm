import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class PaddingContainer extends StatelessWidget {
  const PaddingContainer(
      {super.key,
      required this.child,
      this.padding,
      this.margin,
      this.decoration});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? context.theme.style.pagePadding * 2,
        margin: margin,
        decoration: decoration,
        child: child,
      );
}
