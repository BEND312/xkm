import 'package:hive/hive.dart';

class YKTBox {
  static late Box _box;

  static Future<void> open() async {
    _box = await Hive.openBox('yktBox');
  }

  static T? get<T>(String key) {
    if (!_box.isOpen) return null;
    return _box.get(key) as T?;
  }

  static Future<void> put(String key, dynamic value) async {
    await _box.put(key, value);
  }

  static Future<void> delete(String key) async {
    await _box.delete(key);
  }

  static Future<void> clearCache() async {
    final keys = ['cards'];
    for (final key in keys) {
      await delete(key);
    }
  }
}
