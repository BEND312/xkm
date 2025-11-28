import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../data/m_theme.dart';

class RefreshIcon extends StatefulWidget {
  final Color? color;
  final bool isRefreshing;
  final Function() onRefresh;
  final double? iconDimension;

  const RefreshIcon({
    super.key,
    this.color,
    required this.isRefreshing,
    required this.onRefresh,
    this.iconDimension,
  });

  @override
  State<StatefulWidget> createState() => _RefreshIconState();
}

class _RefreshIconState extends State<RefreshIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isRefreshing) {
        _refreshAnimationController.repeat();
      } else {
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
      }
    });

    return Stack(
      children: [
        IconButton(
          onPressed: widget.onRefresh,
          icon: RotationTransition(
            turns: _refreshAnimationController,
            child: FaIcon(
              FontAwesomeIcons.rotateRight,
              color: widget.color ?? MTheme.backgroundText,
              size: widget.iconDimension ?? 20,
            ),
          ),
        ),
        if (widget.isRefreshing)
          Positioned(
            bottom: 5,
            left: 20 / 2,
            child: Text(
              '刷新中...',
              style: TextStyle(
                fontSize: 8,
                color: MTheme.backgroundText,
              ),
            ),
          ),
      ],
    );
  }
}
