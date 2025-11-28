import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum YKTBillType {
  /// 消费
  consume(
    '消费',
    Colors.orange,
    FontAwesomeIcons.cartShopping,
  ),

  /// 充值
  recharge(
    '充值',
    Colors.green,
    FontAwesomeIcons.moneyBillTransfer,
  ),

  /// 退款
  refund(
    '退款',
    Colors.red,
    FontAwesomeIcons.sackXmark,
  ),

  /// 二维码支付
  qrcodePayment(
    '二维码支付',
    Colors.blue,
    FontAwesomeIcons.qrcode,
  ),

  /// 补助
  subsidy(
    '补助',
    Colors.purple,
    FontAwesomeIcons.handHoldingDollar,
  ),

  /// 其他
  other(
    '其他',
    Colors.grey,
    FontAwesomeIcons.sackDollar,
  );

  final String name;
  final Color color;
  final IconData icon;

  const YKTBillType(this.name, this.color, this.icon);
}
