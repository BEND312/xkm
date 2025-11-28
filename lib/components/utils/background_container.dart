import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class BackgroundContainer extends StatelessWidget {
  const BackgroundContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        color: /*Values.isDarkMode
            ? context.theme.colorScheme.background
            :*/
            context.theme.colorScheme.primaryForeground,
        child: child,
      );
}
