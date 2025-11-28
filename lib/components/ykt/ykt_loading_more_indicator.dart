import 'package:flutter/material.dart';
import 'package:swustmeow/data/m_theme.dart';

class YKTLoadingMoreIndicator extends StatelessWidget {
  const YKTLoadingMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: MTheme.primary2,
            ),
          ),
          SizedBox(width: 12),
          Text(
            '加载更多...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
