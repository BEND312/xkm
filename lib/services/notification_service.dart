import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../data/values.dart';

class NotificationService {
  static late AndroidNotificationChannel androidChannel;

  NotificationService() {
    androidChannel = AndroidNotificationChannel(
        Values.notificationChannelId, '${Values.name} - 服务',
        importance: Importance.high);
  }

  Future<void> init() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();

      await plugin.initialize(
        InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/launcher_icon'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          ),
        ),
      );

      final androidImpl = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.createNotificationChannel(androidChannel);
      await androidImpl?.requestNotificationsPermission();
    } catch (e) {
      // 初始化失败
    }
  }

  Future<void> dispose() async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.cancelAll();
  }

  Future<void> show({
    int? id,
    String? title,
    String? body,
    Importance? importance,
    Priority? priority,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();

    plugin.show(
      id ?? Values.notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          ongoing: true,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: false,
        ),
      ),
    );
  }
}
