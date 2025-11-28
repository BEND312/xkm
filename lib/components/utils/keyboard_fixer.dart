import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

class KeyboardFixer extends StatelessWidget {
  const KeyboardFixer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KeyboardVisibilityBuilder(
      builder: (context, isKeyboardVisible) {
        return AnimatedContainer(
          duration: const Duration(),
          padding: EdgeInsets.only(
            bottom: isKeyboardVisible
                ? MediaQuery.of(context).viewInsets.bottom
                : 0,
          ),
          child: child,
        );
      },
    );
  }
}
