/*
 * Copyright (c) 2025 BEND
 *
 * This file is a new addition to the project, created as part of secondary development.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'package:flutter/services.dart';

class AppLauncherService {
  static const MethodChannel _channel =
      MethodChannel('store.swust.swustmeow/app_launcher');

  static Future<bool> launchAppByPackageName(String packageName) async {
    try {
      final result = await _channel.invokeMethod('launchAppByPackageName', {
        'packageName': packageName,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> launchAppByUri(String uri) async {
    try {
      final result = await _channel.invokeMethod('launchAppByUri', {
        'uri': uri,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isAppInstalled(String packageName) async {
    try {
      final result = await _channel.invokeMethod('isAppInstalled', {
        'packageName': packageName,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> openAppInStore(String packageName) async {
    try {
      final result = await _channel.invokeMethod('openAppInStore', {
        'packageName': packageName,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      if (result is List) {
        return result.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
