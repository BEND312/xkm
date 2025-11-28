/*
 * Copyright (c) 2025 BEND
 *
 * This file is a secondary development based on the original project.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Values {
  static const name = '易通西科喵';

  static String version = '1.0.0'; // 默认值，会被初始化方法覆盖
  static String buildVersion = '1'; // 默认值，会被初始化方法覆盖

  static late PackageInfo packageInfo;

  static const notificationChannelId = 'swuststore';

  static const notificationId = 2233;

  static late DefaultCacheManager cache;

  static List<String> courseTableTimes = [
    '08:00\n09:40',
    '10:00\n11:40',
    '14:00\n15:40',
    '16:00\n17:40',
    '19:00\n20:40',
    '20:40\n22:00'
  ];

  static (DateTime, DateTime, int) getFallbackTermDates(String term) {
    final parts = term.split('-');
    
    if (parts.length >= 2) {
      try {
        final startYear = int.parse(parts[0]);
        final endYear = int.parse(parts[1]);
        final isFirstTerm = term.endsWith('上');
        
        if (isFirstTerm) {
          //TODO: 暂时简易处理
          if (startYear >= 2025) {
            return (DateTime(startYear, 8, 25), DateTime(endYear, 1, 25), 22);
          } else {
            return (DateTime(startYear, 9, 2), DateTime(endYear, 1, 12), 19);
          }
        } else {
          return (DateTime(endYear, 2, 17), DateTime(endYear, 7, 13), 21);
        }
      } catch (e) {
        // 解析失败，使用默认值
      }
    }
    
    final year = DateTime.now().year;
    final isFirstTerm = term.endsWith('上');
    return isFirstTerm
        ? (DateTime(year - 1, 9, 2), DateTime(year, 1, 12), 19)
        : (DateTime(year, 2, 17), DateTime(year, 7, 13), 21);
  }

  static String get fallbackTerm {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    if ((month >= 8 && month <= 12) || month == 1) {
      return '$year-${year + 1}-上';
    } else if (month >= 2 && month <= 7) {
      return '${year - 1}-$year-下';
    }

    return '$year-${year + 1}-上';
  }

  static const String activitiesUrl = 'https://api.s-meow.com/api/v1/public/activities';
  static const String termDatesUrl = 'https://api.s-meow.com/api/v1/public/term-dates';

  static TextStyle dialogButtonTextStyle =
      const TextStyle(fontSize: 12, fontWeight: FontWeight.bold);

  // static ThemeMode? themeMode;

  static ValueNotifier<bool> isDarkMode = ValueNotifier(false);

  static ShimmerEffect skeletonizerEffect = ShimmerEffect(
      baseColor: Colors.grey[/*isDarkMode ? 800 :*/ 300]!,
      highlightColor: Colors.grey[/*isDarkMode ? 600 :*/ 100]!,
      duration: const Duration(seconds: 1));

  static Future<void> initialize() async {
    packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    buildVersion = packageInfo.buildNumber;
  }
}
