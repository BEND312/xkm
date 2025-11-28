import 'package:flutter/material.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/components/ykt/ykt_card_info_panel.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/entity/ykt/ykt_card_account_info.dart';
import 'package:swustmeow/entity/ykt/ykt_secure_keyboard_data.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/components/ykt/ykt_secure_keyboard.dart';

class YKTLossReportPage extends StatefulWidget {
  final YKTCard card;
  final YKTCardAccountInfo account;
  final Function() onRefresh;

  const YKTLossReportPage({
    super.key,
    required this.card,
    required this.account,
    required this.onRefresh,
  });

  @override
  State<YKTLossReportPage> createState() => _YKTLossReportPageState();
}

class _YKTLossReportPageState extends State<YKTLossReportPage> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    bool isLocked = widget.card.isLocked;
    final String actionText = isLocked ? '解除挂失' : '卡片挂失';
    final String confirmText = isLocked ? '确认解挂' : '确认挂失';

    return BasePage(
      headerPad: false,
      header: BaseHeader(title: actionText),
      content: SafeArea(
        top: false,
        child: Column(
          children: [
            YKTCardInfoPanel(card: widget.card, account: widget.account),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    MTheme.radius, 0, MTheme.radius, MTheme.radius),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(MTheme.radius),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLocked ? '解除挂失' : '卡片挂失',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isLocked
                                ? '解除挂失后，您的一卡通将恢复正常使用状态，可以继续进行消费、充值等操作，之后你可以随时挂失。'
                                : '挂失后，您的一卡通将被临时冻结，无法进行任何消费操作，可以有效防止卡片丢失造成的资金损失，之后你可以随时解挂。',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _processLossReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isLocked ? MTheme.primary2 : Colors.red,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processLossReport() async {
    final bool isLocked = widget.card.isLocked;

    if (isLocked) {
      // 解除挂失需要输入密码
      setState(() {
        _isProcessing = true;
      });

      try {
        // 获取安全键盘
        if (GlobalService.yktService == null) {
          showErrorToast('本地服务未启动，请重启 APP');
          return;
        }

        final keyboardResult =
            await GlobalService.yktService!.getSecureKeyboard();

        if (keyboardResult.status != Status.ok) {
          showErrorToast(keyboardResult.value ?? '获取安全键盘失败');
          return;
        }

        setState(() {
          _isProcessing = false;
        });

        // 显示安全键盘
        final keyboardData = keyboardResult.value! as YKTSecureKeyboardData;
        String? password = await _showPasswordKeyboard(keyboardData.keyboard,
            keyboardData.images, keyboardData.keyboardId);

        if (password == null) {
          return;
        }

        setState(() {
          _isProcessing = true;
        });

        // 解挂卡片
        final result = await GlobalService.yktService!
            .unlockCard(widget.card.account, password, keyboardData.keyboardId);

        if (result.status != Status.ok) {
          showErrorToast(result.value ?? '操作失败');
          return;
        }

        showSuccessToast('解挂成功');
        widget.onRefresh();
        if (!mounted) return;
        Navigator.pop(context, true);
      } catch (e) {
        showErrorToast('操作失败: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }

      return;
    }

    // 挂失逻辑保持不变
    setState(() {
      _isProcessing = true;
    });

    try {
      if (GlobalService.yktService == null) {
        showErrorToast('本地服务未启动，请重启 APP');
        return;
      }

      final result =
          await GlobalService.yktService!.lockCard(widget.card.account);

      if (result.status != Status.ok) {
        showErrorToast(result.value ?? '操作失败');
        return;
      }

      showSuccessToast('挂失成功');
      widget.onRefresh();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      showErrorToast('操作失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // 显示安全键盘获取密码
  Future<String?> _showPasswordKeyboard(
      String keyboard, List<String> images, String keyboardId) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: YKTSecureKeyboard(
            keyboard: keyboard,
            images: images,
            maxLength: 6,
            onPasswordComplete: (password) {
              Navigator.pop(context, password);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}
