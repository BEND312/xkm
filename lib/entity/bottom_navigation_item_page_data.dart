import 'package:flutter/material.dart';

class BottomNavigationItemPageData {
  final String name;
  final IconData icon;
  final bool Function() displayGetter;
  final Widget? Function() pageGetter;

  const BottomNavigationItemPageData({
    required this.name,
    required this.icon,
    required this.displayGetter,
    required this.pageGetter,
  });
}
