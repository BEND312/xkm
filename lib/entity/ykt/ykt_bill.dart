import 'package:swustmeow/entity/ykt/ykt_bill_type.dart';

class YKTBill {
  /// 交易类型
  final YKTBillType type;

  /// 卡号
  final String cardAccount;

  /// 支付方式
  final String payName;

  /// 交易金额
  final String transAmount;

  /// 摘要
  final String resume;

  /// 入账时间
  final DateTime effectTime;

  /// 支付时间
  final DateTime payTime;

  /// 是否是支出
  final bool isOutcome;

  /// 订单号
  final String orderId;

  const YKTBill({
    required this.type,
    required this.cardAccount,
    required this.payName,
    required this.transAmount,
    required this.resume,
    required this.effectTime,
    required this.payTime,
    required this.isOutcome,
    required this.orderId,
  });

  factory YKTBill.fromJson(Map<String, dynamic> json) {
    return YKTBill(
      type: YKTBillType.values
              .where((e) => e.name == json['turnoverType'])
              .firstOrNull ??
          YKTBillType.other,
      cardAccount: json['fromAccount'] as String,
      payName: json['payName'] as String,
      transAmount: ((json['tranamt'] as int) / 100).toStringAsFixed(2),
      resume: json['resume'] as String,
      effectTime: DateTime.parse(json['effectdateStr'] as String),
      payTime: DateTime.parse(json['jndatetimeStr'] as String),
      isOutcome: json['toAccount'] as int != 0,
      orderId: json['orderId'] as String,
    );
  }
}
