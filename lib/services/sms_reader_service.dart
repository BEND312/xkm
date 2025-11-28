/*
 * Copyright (c) 2025 BEND
 *
 * This file is a new addition to the project, created as part of secondary development.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:swustmeow/services/sms_interceptor_service.dart';

class SmsMessage {
  final String id;
  final String address;
  final String body;
  final int date;
  final int type;

  SmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.type,
  });

  factory SmsMessage.fromMap(Map<dynamic, dynamic> map) {
    return SmsMessage(
      id: map['id'] as String? ?? '',
      address: map['address'] as String? ?? '',
      body: map['body'] as String? ?? '',
      date: map['date'] as int? ?? 0,
      type: map['type'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'body': body,
      'date': date,
      'type': type,
    };
  }
}

class SmsReaderService {
  static const MethodChannel _channel =
      MethodChannel('store.swust.swustmeow/sms_reader');
  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static Future<bool> checkSmsPermission() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }

  static Future<List<SmsMessage>> getSwustMessages({int limit = 100}) async {
    try {
      final hasPermission = await checkSmsPermission();
      if (!hasPermission) {
        throw Exception('没有短信读取权限');
      }

      final result = await _channel.invokeMethod('getSwustMessages', {
        'limit': limit,
      });

      if (result is List) {
        return result.map((item) => SmsMessage.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<SmsMessage>> getRecentSwustMessages({int count = 10}) async {
    try {
      final hasPermission = await checkSmsPermission();
      if (!hasPermission) {
        throw Exception('没有短信读取权限');
      }

      final result = await _channel.invokeMethod('getRecentSwustMessages', {
        'count': count,
      });

      if (result is List) {
        return result.map((item) => SmsMessage.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> hasSwustMessages() async {
    try {
      final hasPermission = await checkSmsPermission();
      if (!hasPermission) {
        return false;
      }

      final result = await _channel.invokeMethod('hasSwustMessages');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  static String? extractVerificationCode(String message) {
    // 优先匹配6位数字验证码
    final patterns = [
      RegExp(r'验证码[：:为是]?\s*(\d{6})'),
      RegExp(r'验证码\D*(\d{6})'),
      RegExp(r'(\d{6})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(message);
      if (match != null && match.groupCount > 0) {
        final code = match.group(1);
        if (code != null && code.length == 6) {
          return code;
        }
      }
    }

    return null;
  }

  // 系统开启了"禁止第三方应用读取验证码"，则无法使用此方法获取验证码
  static Future<String?> findRecentVerificationCode({
    int maxCount = 5,
    int maxAge = 300,
  }) async {
    try {
      final messages = await getRecentSwustMessages(count: maxCount);
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final message in messages) {
        // 检查短信时间是否在有效范围内
        final age = (now - message.date) ~/ 1000;
        if (age > maxAge) {
          continue;
        }

        // 尝试提取验证码
        final code = extractVerificationCode(message.body);
        if (code != null) {
          return code;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> waitForSms({int timeout = 60}) async {
    try {
      final code = await SmsInterceptorService.waitForVerificationCode(
        timeout: timeout,
      );
      
      if (code != null) {
        return code;
      }
      
    } catch (e) {
      // 不处理异常
    }
    
    try {
      final result = await _channel.invokeMethod('waitForSms', {
        'timeout': timeout,
      });
      
      if (result is String) {
        return result;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  static Stream<String> startSmsListener({
    Duration interval = const Duration(seconds: 1),
    int maxAge = 300,
  }) {
    
    late StreamController<String> controller;
    controller = StreamController<String>(
      onListen: () async {
        final code = await waitForSms(timeout: maxAge);
        if (code != null) {
          controller.add(code);
        }
        controller.close();
      },
    );
    return controller.stream;
  }
}
