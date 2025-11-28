import 'package:hive/hive.dart';
import 'package:swustmeow/entity/ykt/ykt_card_account_info.dart';
import 'package:swustmeow/utils/color.dart';

part 'ykt_card.g.dart';

@HiveType(typeId: 29)
class YKTCard {
  /// 一卡通账号
  @HiveField(0)
  final String account;

  /// 一卡通卡片名称
  @HiveField(1)
  final String cardName;

  /// 一卡通卡片所属部门名称
  @HiveField(2)
  final String departmentName;

  /// 一卡通卡片过期日期
  @HiveField(3)
  final String expireDate;

  /// 一卡通卡片姓名
  @HiveField(4)
  final String name;

  /// 一卡通卡片账户信息列表
  @HiveField(5)
  final List<YKTCardAccountInfo> accountInfos;

  /// 一卡通卡片是否被锁定（挂失）
  @HiveField(6)
  final bool isLocked;

  @HiveField(7)
  late int color;

  YKTCard({
    required this.account,
    required this.cardName,
    required this.departmentName,
    required this.expireDate,
    required this.name,
    required this.accountInfos,
    required this.isLocked,
  }) {
    color = generateColorFromString(account).toInt();
  }
}
