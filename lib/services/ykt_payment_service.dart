import 'package:flutter/material.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/status.dart';

import '../components/ykt/pay/ykt_payment_confirm_sheet.dart';

/// 支付服务工具类
class YKTPaymentService {
  /// 处理支付流程
  static Future<bool> processPayment({
    required BuildContext context,
    required String feeItemId,
    required double amount,
    required Map<String, dynamic> roomData,
    Map<String, dynamic> additionalInfo = const {},
    Function? onSuccess,
  }) async {
    try {
      // 获取订单ID
      final orderIdResult = await GlobalService.yktService!.getPaymentOrderInfo(
        feeItemId: feeItemId,
        amount: amount.toStringAsFixed(2),
        roomData: roomData,
      );

      if (orderIdResult.status != Status.ok) {
        showErrorToast('获取订单失败：${orderIdResult.value}');
        return false;
      }

      final orderId = orderIdResult.value as String;

      // 获取详细支付信息
      final detailInfoResult =
          await GlobalService.yktService!.getDetailedPaymentInfo(
        feeItemId: feeItemId,
        orderId: orderId,
      );

      if (detailInfoResult.status != Status.ok) {
        showErrorToast('获取订单详情失败：${detailInfoResult.value}');
        return false;
      }

      final detailMap = detailInfoResult.value as Map<String, dynamic>;
      final payTypeId = detailMap['paytypeid'] as String;
      final payType = detailMap['paytype'] as String;
      final payName = detailMap['name'] as String;

      // 获取支付确认信息
      final payConfirmInfo =
          await GlobalService.yktService!.getPaymentConfirmInfo(
        feeItemId: feeItemId,
        orderId: orderId,
        payTypeId: payTypeId,
        payType: payType,
      );

      if (payConfirmInfo.status != Status.ok) {
        showErrorToast('获取支付确认信息失败：${payConfirmInfo.value}');
        return false;
      }

      final confirmInfoMap = payConfirmInfo.value as Map<String, dynamic>;
      final balance = confirmInfoMap['balance'] as String;
      final accountType = confirmInfoMap['accountType'] as String;
      final passwordMap = confirmInfoMap['passwordMap'] as Map<String, dynamic>;

      // 显示支付确认表单
      if (!context.mounted) return false;

      await YKTPaymentConfirmSheet.show(
        context: context,
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

      return true;
    } catch (e) {
      showErrorToast('支付处理过程中出错: $e');
      return false;
    }
  }

  /// 处理充值支付流程
  static Future<bool> processRechargePayment({
    required BuildContext context,
    required String orderId,
    required String payTypeId,
    required String payType,
    required String payName,
    required String accountType,
    required String balance,
    required Map<String, dynamic> passwordMap,
    required double amount,
    required Map<String, dynamic> additionalInfo,
    Function? onSuccess,
  }) async {
    try {
      // 显示支付确认表单
      await YKTPaymentConfirmSheet.show(
        context: context,
        orderId: orderId,
        payTypeId: payTypeId,
        payType: payType,
        payName: payName,
        accountType: accountType,
        balance: balance,
        passwordMap: passwordMap,
        amount: amount,
        feeItemId: 'recharge', // 用于标识充值操作
        additionalInfo: additionalInfo,
        onSuccess: onSuccess,
      );

      return true;
    } catch (e) {
      showErrorToast('支付过程中出错: $e');
      return false;
    }
  }
}
