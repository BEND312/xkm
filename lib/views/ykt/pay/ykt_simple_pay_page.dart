import 'package:flutter/material.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/components/ykt/pay/ykt_payment_amount_card.dart';
import 'package:swustmeow/components/ykt/pay/ykt_payment_submit_button.dart';
import 'package:swustmeow/components/ykt/pay/ykt_payment_total_card.dart';
import 'package:swustmeow/components/ykt/ykt_card_info_panel.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/entity/ykt/ykt_pay_app.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/status.dart';

import '../../../services/ykt_payment_service.dart';

class YKTSimplePayPage extends StatefulWidget {
  final List<YKTCard> cards;
  final YKTPayApp payApp;

  const YKTSimplePayPage({
    super.key,
    required this.cards,
    required this.payApp,
  });

  @override
  State<YKTSimplePayPage> createState() => _YKTSimplePayPageState();
}

class _YKTSimplePayPageState extends State<YKTSimplePayPage> {
  bool _isLoading = false;
  bool _isSubmitting = false;

  // 缴费信息
  String _payerName = '';
  double _amount = 0.0;

  // 控制器
  final TextEditingController _amountController = TextEditingController();

  // 添加焦点节点
  final FocusNode _amountFocusNode = FocusNode();

  YKTCard? _useCard;

  @override
  void initState() {
    super.initState();
    _loadPaymentUserInfo();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    final infoResult = await GlobalService.yktService!
        .getPaymentUserInfo(feeItemId: widget.payApp.feeItemId);
    if (infoResult.status != Status.ok) {
      showErrorToast('无法获取支付信息，请重试');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final info = infoResult.value as Map<String, dynamic>;
    final name = info['name'] as String;
    final cardAccount = info['cardAccount'] as String;

    setState(() {
      _payerName = name;
      _useCard =
          widget.cards.where((c) => c.account == cardAccount).firstOrNull;
      _isLoading = false;
    });
  }

  // 处理缴费提交
  Future<void> _handleSubmit() async {
    if (_payerName.isEmpty) {
      showErrorToast('缴费人姓名未知');
      return;
    }

    if (_amount <= 0) {
      showErrorToast('请输入有效的缴费金额');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await YKTPaymentService.processPayment(
        context: context,
        feeItemId: widget.payApp.feeItemId,
        amount: _amount,
        roomData: {},
        additionalInfo: {'支付项目': widget.payApp.name},
        onSuccess: () {
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(title: '${widget.payApp.name}缴费'),
      content: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              // 点击空白区域时移除焦点
              _amountFocusNode.unfocus();
            },
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    children: [
                      if (_useCard != null &&
                          _useCard?.accountInfos.isNotEmpty == true)
                        YKTCardInfoPanel(
                          card: _useCard!,
                          account: _useCard!.accountInfos.first,
                        ),
                      _buildPayerCard(),
                      YKTPaymentAmountCard(
                        amountController: _amountController,
                        amountFocusNode: _amountFocusNode,
                        onAmountChanged: (value) =>
                            setState(() => _amount = value),
                        currentAmount: _amount,
                      ),
                      const SizedBox(height: 12),
                      YKTPaymentTotalCard(amount: _amount),
                      const SizedBox(height: 60), // 为底部浮动按钮留出空间
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: YKTPaymentSubmitButton(
                    onPressed: _handleSubmit,
                    isSubmitting: _isSubmitting,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 缴费人信息卡片
  Widget _buildPayerCard() {
    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          // 缴费人显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Text(
                  '缴费人',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(MTheme.primary2),
                        ),
                      )
                    : Text(
                        _payerName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                        textAlign: TextAlign.right,
                      ),
              ],
            ),
          ),
          // 缴费项目
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  '缴费项目',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const Spacer(),
                Text(
                  widget.payApp.name,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
