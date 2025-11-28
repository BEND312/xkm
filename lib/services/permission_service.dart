import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final _deviceInfoPlugin = DeviceInfoPlugin();

  static Future<PermissionStatus> requestPermission(
      Permission permission) async {
    if (permission == Permission.storage) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      final storageStatus = androidInfo.version.sdkInt < 33
          ? await Permission.storage.request()
          : PermissionStatus.granted;
      return storageStatus;
    }

    var status = await permission.status;
    if (!status.isGranted) {
      status = await permission.request();
    }
    return status;
  }
}
