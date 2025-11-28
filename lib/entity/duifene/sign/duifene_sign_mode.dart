import 'package:hive/hive.dart';

part 'duifene_sign_mode.g.dart';

@HiveType(typeId: 8)
enum DuiFenESignMode {
  /// n秒后签到
  @HiveField(0)
  after,

  /// n秒前签到
  @HiveField(1)
  before,

  /// 随机时间
  @HiveField(2)
  random;
}
