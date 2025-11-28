import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart';
import '../background_service.dart';

class NotificationManager {
  final _notificationPlugin = FlutterLocalNotificationsPlugin();
  final String name;
  final int notificationId;

  NotificationManager({required this.name, required this.notificationId});

  Future<void> configureNotification() async {
    const channel = AndroidNotificationChannel(
      BackgroundService.notificationChannelId,
      '易通西科喵',
      importance: Importance.high,
    );

    await _notificationPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const settings = InitializationSettings(android: androidSettings);
    await _notificationPlugin.initialize(settings);
  }

  void showNotification({
    required bool enabled,
    String? title,
    required String content,
    bool enableVibration = false,
    bool standAlone = false,
  }) {
    if (!enabled) return;

    _notificationPlugin.show(
      !standAlone
          ? notificationId
          : DateTime.now().millisecondsSinceEpoch % 100000,
      title ?? name,
      content,
      NotificationDetails(
        android: AndroidNotificationDetails(
          BackgroundService.notificationChannelId,
          '易通西科喵',
          ongoing: true,
          enableVibration: enableVibration,
          importance: Importance.low,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: standAlone,
          presentBadge: standAlone,
          presentSound: enableVibration && standAlone,
          presentBanner: standAlone,
        ),
      ),
    );
  }

  Future<void> scheduleNotification({
    String? title,
    required String body,
    required DateTime time,
    bool enableVibration = false,
    bool standAlone = true,
  }) async {
    initializeTimeZones();

    final TZDateTime scheduleDate =
        TZDateTime.from(time.toUtc(), getLocation('Asia/Shanghai'));
    await _notificationPlugin.zonedSchedule(
      !standAlone
          ? notificationId
          : DateTime.now().millisecondsSinceEpoch % 100000,
      title ?? name,
      body,
      scheduleDate,
      NotificationDetails(
          android: AndroidNotificationDetails(
              BackgroundService.notificationChannelId, '易通西科喵',
              ongoing: true, enableVibration: enableVibration)),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
