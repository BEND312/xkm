import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:swustmeow/entity/run_mode.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/services/tasks/background_task.dart';

@pragma('vm:entry-point')
class BackgroundService {
  static const String notificationChannelId = 'swustmeow';
  static const int notificationId = 2233;
  static ValueNotifier<bool> isRunning = ValueNotifier(false);
  final RunMode initialRunMode;
  static List<BackgroundTask> tasks = [];
  static int ranTime = 0;
  final bool enableNotification;
  static bool _currentNotificationStatus = true;

  BackgroundService(
      {required this.initialRunMode, required this.enableNotification}) {
    _currentNotificationStatus = enableNotification;
  }

  Future<void> init() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        autoStartOnBoot: false,
        isForegroundMode: false,
        initialNotificationTitle: '易通西科喵运行中',
        initialNotificationContent: '',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
    
  }

  Future<bool> start() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    ranTime = 0;
    return await FlutterBackgroundService().startService();
  }

  static void registerTask(BackgroundTask task) => tasks.add(task);

  List<BackgroundTask> get tasks2 => tasks;

  Future<void> stop() async {
    isRunning.value = false;
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  static bool getIsRunning() => isRunning.value;

  @pragma('vm:entry-point') // 动态调用，防止树摇优化
  static Future<void> _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    ranTime = 0;
    isRunning.value = true;

    service.on('stopService').listen((event) async {
      await service.stopSelf();
      isRunning.value = false;
    });

    service.on('addTask').listen((event) {
      String name = event!['name'] as String;
      BackgroundTask task = GlobalService.backgroundTaskMap[name]!;
      tasks.add(task);
      
    });

    service.on('removeTask').listen((event) async {
      String name = event!['name'] as String;
      BackgroundTask task = GlobalService.backgroundTaskMap[name]!;
      await task.stop(service, _currentNotificationStatus);
      Future.delayed(Duration(seconds: 3), () {
        tasks.remove(task);
      });
      
    });

    service.on('changeNotificationStatus').listen((event) async {
      bool value = event!['value'] as bool;
      _currentNotificationStatus = value;
      if (value) return;

      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.cancelAll();
    });

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      ranTime++;
      for (final task in tasks) {
        final duration = task.duration;
        final seconds = duration.inSeconds;
        final shouldCall = ranTime % seconds == 0;
        if (!shouldCall) return;
        await task.run(service, _currentNotificationStatus);
      }
    });
  }

  @pragma('vm:entry-point')
  Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    return true;
  }
}
