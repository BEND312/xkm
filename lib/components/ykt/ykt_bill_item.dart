import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:swustmeow/entity/ykt/ykt_bill.dart';

class YKTBillItem extends StatelessWidget {
  final YKTBill bill;
  final VoidCallback? onTap;

  const YKTBillItem({
    super.key,
    required this.bill,
    this.onTap,
  });

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return '今天 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (date == yesterday) {
      return '昨天 ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('MM-dd HH:mm').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutcome = bill.isOutcome;
    final String amount =
        isOutcome ? '-${bill.transAmount}' : '+${bill.transAmount}';
    final Color amountColor = isOutcome ? Colors.red : Colors.green;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // 左侧图标
                CircleAvatar(
                  backgroundColor: bill.type.color.withValues(alpha: 0.2),
                  radius: 16,
                  child: FaIcon(
                    bill.type.icon,
                    color: bill.type.color,
                    size: 14,
                  ),
                ),
                SizedBox(width: 10),
                // 中间内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        bill.resume,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: bill.type.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              bill.type.name,
                              style: TextStyle(
                                color: bill.type.color,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            _formatDateTime(bill.payTime),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6),
                // 右侧金额
                Text(
                  amount,
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
