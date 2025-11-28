import 'package:flutter/material.dart';

class DoubleColumn extends StatelessWidget {
  const DoubleColumn(
      {super.key,
      required this.left,
      required this.right,
      this.crossAxisAlignment = CrossAxisAlignment.start});

  final List<Widget> left;
  final List<Widget> right;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: left,
            ),
          ),
          const Padding(padding: EdgeInsets.all(4)),
          Flexible(
            fit: FlexFit.tight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: right,
            ),
          ),
        ],
      );
}
