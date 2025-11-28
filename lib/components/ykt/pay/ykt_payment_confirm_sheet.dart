import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/ykt/ykt_secure_keyboard.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/status.dart';

import '../../../data/m_theme.dart';

/// 支付确认底部表单
class YKTPaymentConfirmSheet extends StatefulWidget {
  final String orderId;
  final String payTypeId;
  final String payType;
  final String payName;
  final String accountType;
  final String balance;
  final Map<String, dynamic> passwordMap;
  final double amount;
  final String feeItemId;
  final Map<String, dynamic> additionalInfo;
  final Function? onSuccess;

  const YKTPaymentConfirmSheet({
    super.key,
    required this.orderId,
    required this.payTypeId,
    required this.payType,
    required this.payName,
    required this.accountType,
    required this.balance,
    required this.passwordMap,
    required this.amount,
    required this.feeItemId,
    this.additionalInfo = const {},
    this.onSuccess,
  });

  /// 显示支付确认表单
  static Future<void> show({
    required BuildContext context,
    required String orderId,
    required String payTypeId,
    required String payType,
    required String payName,
    required String accountType,
    required String balance,
    required Map<String, dynamic> passwordMap,
    required double amount,
    required String feeItemId,
    Map<String, dynamic> additionalInfo = const {},
    Function? onSuccess,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return YKTPaymentConfirmSheet(
          orderId: orderId,
          payTypeId: payTypeId,
          payType: payType,
          payName: payName,
          accountType: accountType,
          balance: balance,
          passwordMap: passwordMap,
          amount: amount,
          feeItemId: feeItemId,
          additionalInfo: additionalInfo,
          onSuccess: onSuccess,
        );
      },
    );
  }

  @override
  State<YKTPaymentConfirmSheet> createState() => _YKTPaymentConfirmSheetState();
}

class _YKTPaymentConfirmSheetState extends State<YKTPaymentConfirmSheet> {
  bool isProcessing = false;
  bool canPopValue = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPopValue,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          final shouldClose =
              await _showDeleteOrderConfirmDialog(widget.orderId);
          if (shouldClose && context.mounted) {
            setState(() => canPopValue = true);
            Navigator.pop(context);
          }
        }
      },
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题和关闭按钮
              Stack(
                alignment: Alignment.center,
                children: [
                  // 居中标题
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      '确认订单',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  // 右侧关闭按钮
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () async {
                        final shouldClose =
                            await _showDeleteOrderConfirmDialog(widget.orderId);
                        if (shouldClose && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 付款详情
              if (widget.additionalInfo.containsKey('房间名称'))
                PaymentInfoRow(
                    label: '房间号', value: widget.additionalInfo['房间名称'] ?? ''),
              if (widget.additionalInfo.containsKey('房间名称'))
                const SizedBox(height: 12),

              if (widget.additionalInfo.containsKey('支付项目'))
                PaymentInfoRow(
                    label: '支付项目', value: widget.additionalInfo['支付项目'] ?? ''),
              if (widget.additionalInfo.containsKey('支付项目'))
                const SizedBox(height: 12),

              PaymentInfoRow(label: '支付方式', value: widget.payName),
              const SizedBox(height: 12),
              PaymentInfoRow(
                  label: '账户类型',
                  value: '${widget.accountType} (￥${widget.balance})'),
              const SizedBox(height: 12),
              PaymentInfoRow(
                label: '付款金额',
                value: '¥ ${widget.amount.toStringAsFixed(2)}',
                isHighlighted: true,
              ),

              const SizedBox(height: 30),

              // 确认缴费按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          setState(() => isProcessing = true);

                          final flag = await _handlePay();

                          setState(() => isProcessing = false);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          if (flag && widget.onSuccess != null) {
                            widget.onSuccess!();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MTheme.primary2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '确认缴费',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // 处理支付
  Future<bool> _handlePay() async {
    try {
      // 获取passwordMap中的第一个键值对
      final firstKey = widget.passwordMap.keys.first;
      final keyboardId = firstKey;
      final keyboardValue = widget.passwordMap[firstKey];

      // 显示安全键盘
      if (!mounted) return false;

      final password = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return YKTSecureKeyboard(
            keyboard: keyboardValue,
            onPasswordComplete: (pwd) {
              Navigator.pop(context, pwd);
            },
            onCancel: () {
              Navigator.pop(context, null);
            },
          );
        },
      );

      // 用户取消输入或未输入完整密码
      if (password == null) {
        showInfoToast('支付已取消');
        return false;
      }

      // 执行支付操作
      if (!mounted) return false;

      final payResult = await GlobalService.yktService?.executePayment(
        feeItemId: widget.feeItemId,
        orderId: widget.orderId,
        payTypeId: widget.payTypeId,
        payType: widget.payType,
        password: password,
        keyboardId: keyboardId,
        accountType: widget.accountType,
      );

      if (!mounted) return false;

      if (payResult == null || payResult.status != Status.ok) {
        showErrorToast('支付失败：${payResult?.value ?? '未知错误'}');
        return false;
      }

      // 支付成功
      showSuccessToast('支付成功');
      return true;
    } catch (e) {
      showErrorToast('支付过程中出错: $e');
      return false;
    }
  }

  // 删除订单
  Future<bool> _deleteOrder(String orderId) async {
    try {
      final result = await GlobalService.yktService!.deletePaymentOrder(
        feeItemId: widget.feeItemId,
        orderId: orderId,
      );
      return result.status == Status.ok;
    } catch (e) {
      showErrorToast('删除订单失败: $e');
      return false;
    }
  }

  // 询问是否删除订单
  Future<bool> _showDeleteOrderConfirmDialog(String orderId) async {
    final result = await showAdaptiveDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return FDialog(
          title: const Text('取消支付'),
          body: const Text('是否要取消本次支付并删除订单？'),
          direction: Axis.horizontal,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('继续支付'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('取消支付'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final deleted = await _deleteOrder(orderId);
      showErrorToast('删除订单失败，请稍后再试');
      return deleted;
    }
    return false;
  }
}

/// 支付信息行组件
class PaymentInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const PaymentInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted ? MTheme.primary2 : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
