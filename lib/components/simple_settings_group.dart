import 'package:flutter/material.dart';

import '../data/m_theme.dart';

class SimpleSettingsGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const SimpleSettingsGroup({
    super.key,
    this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MTheme.radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: MTheme.border),
              borderRadius: BorderRadius.circular(MTheme.radius),
            ),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
