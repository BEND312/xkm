import 'dart:io';

import 'package:flutter/material.dart';
import 'package:swustmeow/components/utils/will_pop_scope_blocker.dart';

import '../../utils/common.dart';

class BackAgainBlocker extends StatefulWidget {
  const BackAgainBlocker({super.key, required this.child});

  final Widget child;

  @override
  State<StatefulWidget> createState() => _BackAgainBlockerState();
}

class _BackAgainBlockerState extends State<BackAgainBlocker> {
  DateTime? _lastPressed;

  @override
  void initState() {
    super.initState();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScopeBlocker(
      onCheckPop: (didPop) {
        final now = DateTime.now();
        if (_lastPressed == null ||
            now.difference(_lastPressed!) > const Duration(seconds: 2)) {
          _refresh(() => _lastPressed = now);
          showInfoToast('再次返回以退出');
          return false;
        } else {
          _refresh(() => _lastPressed = null);
          exit(0);
        }
      },
      child: widget.child,
    );
  }
}
