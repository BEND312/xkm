import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import '../../utils/common.dart';

class HTMLView extends StatelessWidget {
  final String html;

  const HTMLView({super.key, required this.html});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return HtmlWidget(
          html,
          textStyle: TextStyle(color: Colors.black),
          onTapUrl: (url) => launchLink(url),
        );
      },
    );
  }
}