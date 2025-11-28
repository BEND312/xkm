import 'package:hive/hive.dart';

part 'color_mode.g.dart';

@HiveType(typeId: 32)
enum ColorMode {
  @HiveField(0)
  theme, // 统一使用主题色

  @HiveField(1)
  colorful, // 使用预设彩色方案

  @HiveField(2)
  palette, // 使用图片提取配色
}
