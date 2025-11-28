import 'package:hive/hive.dart';

part 'ykt_auth_token.g.dart';

@HiveType(typeId: 30)
class YKTAuthToken {
  /// 访问授权码
  @HiveField(0)
  final String accessToken;

  /// 刷新授权码
  @HiveField(1)
  final String refreshToken;

  /// 过期时间
  ///
  /// 单位：秒？
  @HiveField(2)
  final int expiresIn;

  /// Token 类型
  @HiveField(3)
  final String tokenType;

  /// 创建时间
  @HiveField(4)
  final DateTime createdAt;

  YKTAuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
    required this.createdAt,
  });

  DateTime get expiresAt => createdAt.add(Duration(seconds: expiresIn));

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
