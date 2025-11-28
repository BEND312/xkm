import 'package:flutter/material.dart';

class WillPopScopeBlocker extends StatefulWidget {
  const WillPopScopeBlocker({
    super.key,
    required this.onCheckPop,
    required this.child,
  });

  final bool Function(bool didPop) onCheckPop;
  final Widget child;

  @override
  State<StatefulWidget> createState() => _WillPopScopeBlockerState();
}

class _WillPopScopeBlockerState extends State<WillPopScopeBlocker> {
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) {
        final result = widget.onCheckPop(didPop);
        setState(() => _canPop = result);
      },
      child: widget.child,
    );
  }
}
