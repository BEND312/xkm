import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/entity/activity_type.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/list.dart';

import '../data/greetings.dart';
import '../data/m_theme.dart';
import '../entity/activity.dart';
import '../services/value_service.dart';
import '../utils/time.dart';

class Greeting extends StatefulWidget {
  const Greeting({super.key, required this.activities});

  final List<Activity> activities;

  @override
  State<StatefulWidget> createState() => _GreetingState();
}

class _GreetingState extends State<Greeting>
    with SingleTickerProviderStateMixin {
  static const fallbackGreeting = '易通西科喵';
  bool _isFirstOpen = true;
  String? _currentGreeting;
  Timer? _timer;
  Timer? _clickTimer;
  int _clickCount = 0;
  DateTime? _lastClickTime;
  bool _isInEasterEgg = false;
  final Duration _resetThreshold = const Duration(seconds: 10);
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _timer = _timer ??
        Timer.periodic(const Duration(minutes: 1), (_) => _updateGreeting());
    _clickTimer = _clickTimer ??
        Timer.periodic(const Duration(seconds: 1), (_) {
          final now = DateTime.now();
          // 如果是第一次点击，或上次点击超过10秒，重置计数和状态
          if (_lastClickTime != null &&
              _isInEasterEgg &&
              now.difference(_lastClickTime!) >= _resetThreshold) {
            _cancelEasterEgg();
          }
        });
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clickTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  void _cancelEasterEgg() {
    _refresh(() {
      _clickCount = 0;
      _isInEasterEgg = false;
      _lastClickTime = null;
    });
    _updateGreeting();
  }

  bool _generateActivityGreeting() {
    var activities = widget.activities
        .where((ac) => ac.isInActivity(DateTime.now()))
        .toList()
      ..sort((a, b) => ActivityTypeData.of(b.type)
          .priority
          .compareTo(ActivityTypeData.of(a.type).priority));

    if (activities.isEmpty) return false;
    final first = activities.length > 1
        ? activities.firstWhere((c) => c.type != ActivityType.today)
        : activities.first;
    if (first.greetings == null || first.greetings?.isNotEmpty != true) {
      return false;
    }

    final greeting = first.greetings!.randomElement;
    ValueService.currentGreeting = greeting;
    _refresh(() => _currentGreeting = greeting);
    return true;
  }

  void _generateTimeGreeting() {
    final now = DateTime.now();
    final w = timeGreetings.where((entry) {
      final lr = (entry['time'] as String).split('-');
      return isHourMinuteInRange(now.hmString, lr.first, lr.last, ':');
    });
    final result = w.isEmpty
        ? fallbackGreeting
        : (w.first['greetings'] as List<String>).randomElement;
    ValueService.currentGreeting = result;
    _refresh(() => _currentGreeting = result);
  }

  void _updateGreeting() {
    if (ValueService.currentGreeting != null) return;
    if (!_isInEasterEgg) {
      final activity = _generateActivityGreeting();
      if (!activity) _generateTimeGreeting();
    }
  }

  void _handleClick() {
    final now = DateTime.now();
    _refresh(() {
      _lastClickTime = now;
      _clickCount++;
    });

    if (_clickCount == 5 && now.month == 4 && now.day == 1) {
      showSuccessToast('发现彩蛋：愚人节快乐！', seconds: 10);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateGreeting();

    // 用来修复 `emoji` 导致的文字下垂
    const strutStyle = StrutStyle(forceStrutHeight: true, height: 3.2);
    final style = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: MTheme.backgroundText,
    );

    final result =
        _currentGreeting ?? ValueService.currentGreeting ?? fallbackGreeting;

    return FTappable(
      onPress: () {
        if (_animationController.isAnimating ||
            _animationController.isCompleted) {
          _animationController.reset();
        }
        _animationController.forward();
        _handleClick();
      },
      child: SizedBox(
        child: Align(
          alignment: Alignment.topLeft,
          child: AutoSizeText(
            result,
            style: style,
            strutStyle: strutStyle,
            maxLines: 1,
            maxFontSize: 24,
            minFontSize: 6,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          )
              .animate(
                  controller: _animationController,
                  onPlay: (controller) {
                    if (_isFirstOpen) {
                      controller.stop();
                      _isFirstOpen = false;
                    }
                  })
              // .shimmer(color: Colors.grey)
              .shakeX(hz: 3, amount: 2),
        ),
      ),
    );
  }
}
