import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:swustmeow/services/tasks/background_task.dart';

class DuiFenEHomeworkTask extends BackgroundTask {
  DuiFenEHomeworkTask()
      : super(name: '对分易作业服务', duration: const Duration(minutes: 10));

  @override
  Future<void> run(ServiceInstance service, bool enableNotification) {
    // TODO: implement run
    throw UnimplementedError();
  }

  @override
  // TODO: implement shouldAutoStart
  Future<bool> get shouldAutoStart => throw UnimplementedError();

  @override
  Future<void> stop(ServiceInstance service, bool enableNotification) {
    // TODO: implement stop
    throw UnimplementedError();
  }
}
