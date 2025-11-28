import 'package:flutter/material.dart';
import 'package:swustmeow/data/m_theme.dart';

/// 支付金额输入卡片
class YKTPaymentAmountCard extends StatefulWidget {
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final Function(double) onAmountChanged;
  final double currentAmount;
  final List<List<double>> amountOptions;
  final String title;

  const YKTPaymentAmountCard({
    super.key,
    required this.amountController,
    required this.amountFocusNode,
    required this.onAmountChanged,
    required this.currentAmount,
    this.amountOptions = const [
      [10, 50, 100]
    ],
    this.title = '请输入缴费金额',
  });

  @override
  State<YKTPaymentAmountCard> createState() => _YKTPaymentAmountCardState();
}

class _YKTPaymentAmountCardState extends State<YKTPaymentAmountCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MTheme.radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
          ),
          for (var row in widget.amountOptions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children:
                    row.map((amount) => _buildAmountButton(amount)).toList(),
              ),
            ),
          const SizedBox(height: 8),
          _buildCustomAmountInput(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // 金额按钮
  Widget _buildAmountButton(double amount) {
    bool isSelected = widget.currentAmount == amount;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectAmount(amount),
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? MTheme.primary2 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(MTheme.radius),
            color: isSelected
                ? MTheme.primary2.withValues(alpha: 0.08)
                : Colors.grey.shade50,
          ),
          child: Center(
            child: Text(
              '${amount.toInt()}元',
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? MTheme.primary2 : const Color(0xFF666666),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 自定义金额输入
  Widget _buildCustomAmountInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: widget.amountController,
        focusNode: widget.amountFocusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: '请输入金额',
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MTheme.radius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MTheme.radius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(MTheme.radius),
            borderSide: BorderSide(color: MTheme.primary2, width: 1),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Icon(Icons.currency_yen, color: MTheme.primary2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (value) {
          if (value.isEmpty) {
            widget.onAmountChanged(0);
            return;
          }

          // 解析输入值
          double parsedValue = double.tryParse(value) ?? 0;

          // 检查小数位数是否超过两位
          if (value.contains('.')) {
            List<String> parts = value.split('.');
            if (parts.length > 1 && parts[1].length > 2) {
              // 截断到两位小数
              String truncatedValue = '${parts[0]}.${parts[1].substring(0, 2)}';
              parsedValue = double.parse(truncatedValue);

              // 更新文本框显示的值
              widget.amountController.value = TextEditingValue(
                text: truncatedValue,
                selection:
                    TextSelection.collapsed(offset: truncatedValue.length),
              );
            }
          }

          widget.onAmountChanged(parsedValue);
        },
      ),
    );
  }

  // 选择预设金额
  void _selectAmount(double amount) {
    widget.onAmountChanged(amount);
    widget.amountController.text = amount.toStringAsFixed(2);
  }
}
