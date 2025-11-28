import 'package:hive/hive.dart';

part 'run_mode.g.dart';

@HiveType(typeId: 6)
enum RunMode {
  @HiveField(0)
  foreground,
  @HiveField(1)
  background;
}
