import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/data/m_theme.dart';

import '../components/base_webview.dart';
import '../components/utils/base_header.dart';
import '../components/utils/base_page.dart';

class SimpleWebViewPage extends StatefulWidget {
  const SimpleWebViewPage({
    super.key,
    required this.initialUrl,
    this.title,
  });

  final String initialUrl;
  final String? title;

  @override
  State<StatefulWidget> createState() => _SimpleWebViewPageState();
}

class _SimpleWebViewPageState extends State<SimpleWebViewPage> {
  String? _title;
  InAppWebViewController? _controller;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
  }

  @override
  void dispose() {
    if (_controller != null && !_disposed) {
      _controller?.dispose();
      _controller = null;
    }
    super.dispose();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(
        title: Text(
          widget.title != null ? widget.title! : _title ?? '网页',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: MTheme.backgroundText,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        suffixIcons: [
          IconButton(
            onPressed: () async {
              if (_disposed) return;
              await _controller?.reload();
            },
            icon: FaIcon(
              FontAwesomeIcons.rotateRight,
              color: MTheme.backgroundText,
              size: 20,
            ),
          )
        ],
      ),
      content: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(MTheme.radius),
          topRight: Radius.circular(MTheme.radius),
        ),
        child: BaseWebView(
          url: widget.initialUrl,
          onDispose: () => _disposed = true,
          onTitleChanged: (_, title) {
            if (title == null) return;
            _refresh(() => _title = title);
          },
        ),
      ),
    );
  }
}
