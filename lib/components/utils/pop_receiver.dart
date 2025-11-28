import 'package:flutter/material.dart';

class PopReceiver extends StatelessWidget {
  const PopReceiver({super.key, required this.onPop, required this.child});

  final Function() onPop;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, __) {
        if (!didPop) return;
        onPop();
      },
      child: child,
    );
  }
}
