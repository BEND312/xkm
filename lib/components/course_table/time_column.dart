import 'dart:async';

import 'package:flutter/material.dart';
import 'package:swustmeow/data/m_theme.dart';

import '../../utils/time.dart';

class TimeColumn extends StatefulWidget {
  const TimeColumn({super.key, required this.number, required this.time});

  final int number;
  final String time;

  @override
  State<StatefulWidget> createState() => _TimeColumnState();
}

class _TimeColumnState extends State<TimeColumn> {
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = _timer ??
        Timer.periodic(const Duration(seconds: 1),
            (_) => _refresh(() => _currentTime = DateTime.now()));
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const splitPattern = ':';
    final splitRes = widget.time.split('\n');
    final inRange = isHourMinuteInRange(
        _currentTime.hmString, splitRes[0], splitRes[1], splitPattern);
    final hasBg = MTheme.courseTableImagePath != null;
    final style = TextStyle(
      color: hasBg
          ? inRange
              ? MTheme.courseTableText
              : MTheme.courseTableUseWhiteFont
                  ? Colors.white
                  : Colors.black
          : Colors.black,
    );

    return SizedBox(
      width: 34,
      child: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
            ),
            Text(widget.number.toString(),
                textAlign: TextAlign.center,
                style: style.copyWith(fontSize: 10)),
            Text(
              widget.time,
              textAlign: TextAlign.center,
              style: style.copyWith(fontSize: 8),
            )
          ],
        ),
      ),
    );
  }
}
