import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:swustmeow/data/global_keys.dart';
import 'package:swustmeow/entity/uri_listener.dart';
import 'package:swustmeow/services/value_service.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/views/course_table/course_table_page.dart';
import 'package:swustmeow/views/main_page.dart';

class UriSubscriptionService {
  StreamSubscription<Uri?>? _linkSubscription;
  final List<UriListener> _listeners = [];
  static final _appLinks = AppLinks();

  Future<void> initUriListener() async {
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      _handleUri(uri);
    }, onError: (err) {
      // 错误处理
    });

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleUri(initialUri);
    }
  }

  Future<void> dispose() async {
    _listeners.clear();
    await _linkSubscription?.cancel();
  }

  void addListener(UriListener listener) {
    _listeners.add(listener);
  }

  void _handleUri(Uri? uri) {
    if (uri != null) {
      final host = uri.host;
      final path = uri.path;
      for (final entry
          in _listeners.where((e) => e.action == host && e.path == path)) {
        entry.callback(uri);
      }
    }
  }

  void initDefaultListeners(BuildContext context) {
    addListener(
      UriListener('jump', '/course_table', (uri) {
        final navigator = GlobalKeys.navigatorKey.currentState;
        if (navigator != null) {
          pushToWithoutContext(
            navigator,
            '/course_table',
            CourseTablePage(
                    containers: ValueService.coursesContainers,
            currentContainer: ValueService.currentCoursesContainer.value!,
                    activities: ValueService.activities,
                    showBackButton: true,
                  ),
          );
        }
      }),
    );
  }
}
