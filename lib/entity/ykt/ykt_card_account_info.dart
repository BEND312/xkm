import 'package:hive/hive.dart';

part 'ykt_card_account_info.g.dart';

/// 卡片账户信息
@HiveType(typeId: 31)
class YKTCardAccountInfo {
  /// 账户名称
  @HiveField(0)
  final String name;

  /// 账户类型？
  ///
  /// 原 API 格式：卡片账户-编号，例：100816-000
  @HiveField(1)
  final String type;

  /// 账户余额
  ///
  /// 原 API 格式例：6099（表示￥60.99），
  /// 需要解析为 60.99
  @HiveField(2)
  final String balance;

  const YKTCardAccountInfo({
    required this.name,
    required this.type,
    required this.balance,
  });
}
