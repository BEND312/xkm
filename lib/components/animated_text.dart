import 'dart:async';

import 'package:flutter/material.dart';

class AnimatedText extends StatefulWidget {
  const AnimatedText(
      {super.key, required this.textList, this.duration, this.textStyle});

  final List<String> textList;
  final Duration? duration;
  final TextStyle? textStyle;

  @override
  State<StatefulWidget> createState() => _AnimatedTextState();
}

class _AnimatedTextState extends State<AnimatedText> {
  late Timer _timer;
  int index = 0;

  void _startTimer(void Function(Timer timer) onSec) {
    final dur = widget.duration ?? const Duration(seconds: 1);
    _timer = Timer.periodic(dur, (Timer timer) => onSec(timer));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startTimer((Timer timer) {
      _refresh(() => index += 1);
      if (index == widget.textList.length) _refresh(() => index = 0);
    });
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) =>
      Text(widget.textList[index], style: widget.textStyle);
}
