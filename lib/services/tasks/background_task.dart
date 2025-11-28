import 'package:flutter_background_service/flutter_background_service.dart';

abstract class BackgroundTask {
  const BackgroundTask({required this.name, required this.duration});

  final String name;
  final Duration duration;

  Future<bool> get shouldAutoStart;

  Future<void> run(ServiceInstance service, bool enableNotification);

  Future<void> stop(ServiceInstance service, bool enableNotification);

  Future<void> invoke(ServiceInstance service, String method,
      [Map<String, dynamic>? args]) async {
    if (service is AndroidServiceInstance &&
        await service.isForegroundService()) {
      service.invoke(method, args);
    } else {
      final s = FlutterBackgroundService();
      s.invoke(method, args);
    }
  }
}
