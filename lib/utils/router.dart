import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swustmeow/components/utils/pop_receiver.dart';
import 'package:swustmeow/services/value_service.dart';

Route _buildRoute(Widget widget, {required bool pushInto}) {
  if (Platform.isIOS) {
    return CupertinoPageRoute(builder: (context) => widget);
  } else {
    if (pushInto) {
      return MaterialPageRoute(builder: (context) => widget);
    }

    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => widget,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}

void _onPop() {
  final path = ValueService.currentPath.value;
  var segments = path.split('/');
  if (segments.length > 1) {
    segments.removeLast();
    ValueService.currentPath.value = segments.join('/');
  }
  ValueService.currentPath.value = '/';
}

void pushTo(
  BuildContext context,
  String path,
  Widget widget, {
  bool pushInto = false,
  bool force = false,
}) {
  if (ValueService.currentPath.value == path && !force) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ValueService.currentPath.value = path;
    Navigator.push(
      context,
      _buildRoute(
        PopReceiver(onPop: _onPop, child: widget),
        pushInto: pushInto,
      ),
    );
  });
}

void pushReplacement(
  BuildContext context,
  String path,
  Widget widget, {
  bool pushInto = false,
  bool force = false,
}) {
  if (ValueService.currentPath.value == path && !force) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ValueService.currentPath.value = path;
    Navigator.pushAndRemoveUntil(
      context,
      _buildRoute(PopReceiver(onPop: _onPop, child: widget),
          pushInto: pushInto),
      (_) => false,
    );
  });
}

void pushToWithoutContext(
  NavigatorState navigator,
  String path,
  Widget widget, {
  bool pushInto = false,
  bool force = false,
}) {
  if (ValueService.currentPath.value == path && !force) return;
  ValueService.currentPath.value = path;
  navigator.push(
    _buildRoute(
      PopReceiver(onPop: _onPop, child: widget),
      pushInto: pushInto,
    ),
  );
}
