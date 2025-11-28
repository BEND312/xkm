import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/ykt/ykt_bill.dart';

class YKTBillDetailPage extends StatelessWidget {
  final YKTBill bill;

  const YKTBillDetailPage({
    super.key,
    required this.bill,
  });

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日 HH:mm:ss').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '账单详情'),
      content: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(MTheme.radius),
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withValues(alpha: 0.08),
              //     blurRadius: 8,
              //     offset: Offset(0, 2),
              //   ),
              // ],
            ),
            child: Column(
              children: [
                _buildHeaderCard(),
                SizedBox(height: 16),
                _buildDetailsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final bool isOutcome = bill.isOutcome;
    final Color amountColor = isOutcome ? Colors.red : Colors.green;
    final String amountText =
        isOutcome ? '-${bill.transAmount}' : '+${bill.transAmount}';

    return Column(
      children: [
        CircleAvatar(
          backgroundColor: bill.type.color.withValues(alpha: 0.2),
          radius: 18,
          child: FaIcon(
            bill.type.icon,
            color: bill.type.color,
            size: 16,
          ),
        ),
        SizedBox(height: 8),
        Text(
          bill.payName,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Text(
          amountText,
          style: TextStyle(
            color: amountColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '交易详情',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        _buildDetailItem('付款方式', bill.payName),
        _buildDetailItem('付款账户', bill.cardAccount),
        _buildDetailItem('说明', bill.resume),
        _buildDetailItem('交易时间', _formatDateTime(bill.payTime)),
        _buildDetailItem('入账时间', _formatDateTime(bill.effectTime)),
        _buildDetailItem('订单号', bill.orderId),
        _buildDetailItem('交易类型', bill.isOutcome ? '支出' : '收入'),
        _buildDetailItem('账单分类', bill.type.name),
      ],
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
