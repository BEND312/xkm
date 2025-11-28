import 'package:flutter/material.dart';

class RouteObserverHelper extends NavigatorObserver {
  final VoidCallback onRouteChanged;

  RouteObserverHelper(this.onRouteChanged);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChanged();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
