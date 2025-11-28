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
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SmsInterceptorService {
  static const MethodChannel _channel =
      MethodChannel('store.swust.swustmeow/sms_interceptor');

  static bool _isListening = false;
  static final List<StreamController<SmsReceivedEvent>> _controllers = [];
  static void initialize() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final sender = call.arguments['sender'] as String;
        final body = call.arguments['body'] as String;
        final timestamp = call.arguments['timestamp'] as int;

        final event = SmsReceivedEvent(
          sender: sender,
          body: body,
          timestamp: timestamp,
        );

        for (final controller in _controllers) {
          if (!controller.isClosed) {
            controller.add(event);
          }
        }
      }
    });
  }

  static Future<bool> requestSmsPermission() async {
    try {
      final result = await _channel.invokeMethod('requestSmsPermission');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> startInterceptor() async {
    try {
      await _channel.invokeMethod('startInterceptor');
      _isListening = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> stopInterceptor() async {
    try {
      await _channel.invokeMethod('stopInterceptor');
      _isListening = false;
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> waitForVerificationCode({
    int timeout = 60,
  }) async {

    final completer = Completer<String?>();
    final controller = StreamController<SmsReceivedEvent>();
    _controllers.add(controller);
    if (!_isListening) {
      final started = await startInterceptor();
      if (!started) {
        _controllers.remove(controller);
        return null;
      }
    }

    Timer? timeoutTimer;
    StreamSubscription? subscription;

    subscription = controller.stream.listen((event) {
      final code = _extractVerificationCode(event.body);
      if (code != null && !completer.isCompleted) {
        completer.complete(code);
        timeoutTimer?.cancel();
        subscription?.cancel();
        _controllers.remove(controller);
        controller.close();
      }
    });

    timeoutTimer = Timer(Duration(seconds: timeout), () {
      if (!completer.isCompleted) {
        completer.complete(null);
        subscription?.cancel();
        _controllers.remove(controller);
        controller.close();
      }
    });

    return completer.future;
  }

  static String? _extractVerificationCode(String message) {
    final patterns = [
      RegExp(r'验证码[：:为是]?\s*(\d{6})'),
      RegExp(r'验证码\D*(\d{6})'),
      RegExp(r'code[：:为是]?\s*(\d{6})', caseSensitive: false),
      RegExp(r'\b(\d{6})\b'),
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

  static void dispose() {
    for (final controller in _controllers) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
    stopInterceptor();
  }
}

class SmsReceivedEvent {
  final String sender;
  final String body;
  final int timestamp;

  SmsReceivedEvent({
    required this.sender,
    required this.body,
    required this.timestamp,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  String toString() {
    return 'SmsReceivedEvent(sender: $sender, timestamp: $timestamp, body: $body)';
  }
}
