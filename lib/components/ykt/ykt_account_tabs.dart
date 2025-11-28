import 'package:flutter/material.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';

class YKTAccountTabs extends StatelessWidget {
  final YKTCard card;
  final int currentAccountIndex;
  final Function(int) onAccountChanged;

  const YKTAccountTabs({
    super.key,
    required this.card,
    required this.currentAccountIndex,
    required this.onAccountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accounts = card.accountInfos;

    // 如果只有一个账户，显示简单信息而不是标签
    if (accounts.length == 1) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          '当前账户: ${accounts[0].name}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20, bottom: 8),
          child: Text(
            '选择账户',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              final isSelected = index == currentAccountIndex;

              return GestureDetector(
                onTap: () => onAccountChanged(index),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(card.color)
                        : Color(card.color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Color(card.color).withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    account.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Color(card.color),
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 显示所选账户余额
        if (accounts.isNotEmpty && currentAccountIndex < accounts.length)
          Padding(
            padding: EdgeInsets.only(left: 20, top: 8),
            child: RichText(
              text: TextSpan(
                text: '当前余额: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                children: [
                  TextSpan(
                    text: '￥${accounts[currentAccountIndex].balance}',
                    style: TextStyle(
                      color: Color(card.color),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
