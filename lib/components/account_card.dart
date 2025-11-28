/*
 * Copyright (c) 2025 BEND
 *
 * This file is a secondary development based on the original project.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'package:flutter/material.dart';
import 'package:swustmeow/entity/account.dart';
import 'package:swustmeow/services/account/account_service.dart';
import 'package:swustmeow/services/account/soa_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/views/login_page.dart';
import 'package:swustmeow/services/sms_reader_service.dart';
import 'package:swustmeow/services/boxes/common_box.dart';

import '../data/m_theme.dart';

class AccountCard extends StatefulWidget {
  const AccountCard({
    super.key,
    required this.service,
    required this.color,
  });

  final AccountService service;
  final Color color;

  @override
  State<StatefulWidget> createState() => _AccountCardState();
}

class _AccountCardState extends State<AccountCard> {
  Account? _isSwitching;

  @override
  void initState() {
    super.initState();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  Widget _buildSwitchingOverlay(Account account) {
    if (_isSwitching?.equals(account) != true) return const SizedBox.shrink();

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(MTheme.radius),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '切换中...',
                style: TextStyle(
                  color: widget.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentAccount = widget.service.currentAccount;
    final accounts = widget.service.savedAccounts;

    return ValueListenableBuilder(
      valueListenable: widget.service.isLoginNotifier,
      builder: (context, isLoginV, _) {
        final isLogin = isLoginV;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MTheme.radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_circle,
                      color: widget.color,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    widget.service.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isLogin ? Colors.green : Colors.red)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isLogin ? '已登录' : '未登录',
                      style: TextStyle(
                        color: isLogin ? Colors.green : Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              if (accounts.isNotEmpty) ...[
                SizedBox(height: 14),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                SizedBox(height: 14),

                // 账号列表
                ...accounts.map((account) {
                  final isCurrent = currentAccount?.equals(account) ?? false;
                  return Stack(
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? widget.color.withValues(alpha: 0.05)
                              : Colors.grey.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: isCurrent
                              ? Border.all(
                                  color: widget.color.withValues(alpha: 0.2),
                                  width: 1,
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            // 账号信息
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    isCurrent
                                        ? Icons.check_circle
                                        : Icons.account_circle_outlined,
                                    color: isCurrent
                                        ? widget.color
                                        : Colors.grey.shade600,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      account.username ?? account.account,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: isCurrent
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 操作按钮
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isCurrent && isLogin)
                                  _buildActionButton('切换', MTheme.primary2,
                                      () async {
                                    _refresh(() => _isSwitching = account);
                                    await _switch(account, '切换');
                                    _refresh(() => _isSwitching = null);
                                  }),
                                if (!isCurrent && !isLogin)
                                  _buildActionButton('登录', Colors.green,
                                      () => _autoLogin(account)),
                                if (isCurrent)
                                  _buildActionButton('退出', Colors.red, _logout),
                                if (!isCurrent) ...[
                                  SizedBox(width: 4),
                                  _buildActionButton(
                                    '删除',
                                    Colors.red,
                                    () => _delete(account),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildSwitchingOverlay(account),
                    ],
                  );
                }),
              ] else
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      '暂无保存的账号',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              // 添加新账号按钮
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addAccount,
                  icon: Icon(Icons.add, size: 16, color: Colors.white),
                  label: Text('添加新账号', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  ),
                ),
              ]
          )
        );
      },
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _switch(Account account, String type) async {
    _refresh(() => _isSwitching = account);

    try {
      final r = await widget.service.switchTo(account);

      if (r.status == Status.ok) {
        showSuccessToast('$type成功！');
        if (!mounted) return;
        setState(() {});
      } else {
        showErrorToast('$type失败：${r.value}');
      }
    } finally {
      _refresh(() => _isSwitching = null);
    }
  }

  Future<void> _autoLogin(Account account) async {
    
    if (widget.service is! SOAService) {
      await _switch(account, '登录');
      return;
    }

    final isSmsAccount = account.password.isEmpty;
    final smsAutoFillEnabled = CommonBox.get('smsAutoFillEnabled') as bool? ?? false;
    
    if (isSmsAccount && !smsAutoFillEnabled) {
      showErrorToast('请在设置中开启"短信自动填充登录"功能，或删除账号后重新添加');
      return;
    }

    if (!isSmsAccount && !smsAutoFillEnabled) {
      await _switch(account, '登录');
      return;
    }

    if (!isSmsAccount) {
      await _switch(account, '登录');
      return;
    }

    _refresh(() => _isSwitching = account);

    try {
      final hasPermission = await SmsReaderService.checkSmsPermission();
      
      if (!hasPermission) {
        final granted = await SmsReaderService.requestSmsPermission();
        
        if (!granted) {
          showErrorToast('需要短信权限才能自动登录');
          _refresh(() => _isSwitching = null);
          return;
        }
      }

      final phone = account.account;
      
      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
        showErrorToast('账号格式不正确，需要手机号');
        _refresh(() => _isSwitching = null);
        return;
      }

      showInfoToast('正在发送验证码...');

      final api = (widget.service as SOAService).api;
      if (api == null) {
        showErrorToast('服务未初始化');
        _refresh(() => _isSwitching = null);
        return;
      }

      final sendResult = await api.getDynamicCode(phone);
      
      if (sendResult.status != Status.ok) {
        showErrorToast('发送验证码失败：${sendResult.value}');
        _refresh(() => _isSwitching = null);
        return;
      }

      final message = sendResult.value?.toString() ?? '';
      bool isDuplicateSend = message.contains('已经发送') || message.contains('请勿重复提交');
      
      if (isDuplicateSend) {
        showInfoToast('检测到上次验证码，正在尝试读取...');
        final recentCode = await SmsReaderService.findRecentVerificationCode(
          maxCount: 3,  // 查找最近3条短信
          maxAge: 300,  // 5分钟内的短信
        );
        
        if (recentCode != null) {
          showInfoToast('找到验证码: $recentCode，正在登录...');
          final loginResult = await (widget.service as SOAService).loginByPhone(
            phone: phone,
            code: recentCode,
          );

          if (loginResult.status == Status.ok) {
            showSuccessToast('登录成功！');
            if (!mounted) return;
            setState(() {});
            _refresh(() => _isSwitching = null);
            return;
          } else {
            showErrorToast('上次验证码已失效或不正确\n请等待5分钟后重试\n错误：${loginResult.value}');
            _refresh(() => _isSwitching = null);
            return;
          }
        } else {
          showErrorToast('未找到最近的验证码\n验证码可能已发送，请等待5分钟后重试');
          _refresh(() => _isSwitching = null);
          return;
        }
      }

      showInfoToast('验证码已发送，正在等待短信...');

      final code = await SmsReaderService.waitForSms(timeout: 60);
      
      if (code == null) {
        showErrorToast('未收到验证码，请稍后重试');
        _refresh(() => _isSwitching = null);
        return;
      }
      

      showInfoToast('收到验证码，正在登录...');
      final loginResult = await (widget.service as SOAService).loginByPhone(
        phone: phone,
        code: code,
      );

      if (loginResult.status == Status.ok) {
        showSuccessToast('自动登录成功！');
        if (!mounted) return;
        setState(() {});
      } else {
        showErrorToast('登录失败：${loginResult.value}');
      }
    } catch (e) {
      showErrorToast('自动登录异常：$e');
    } finally {
      _refresh(() => _isSwitching = null);
    }
  }

  Future<void> _delete(Account account) async {
    await widget.service.deleteAccount(account);
    setState(() {});
    if (!mounted) return;
    showSuccessToast('删除成功！');
  }

  Future<void> _addAccount() async {
    bool autoSendCode = false;
    if (widget.service is SOAService) {
      final hasPermission = await SmsReaderService.requestSmsPermission();
      if (hasPermission) {
        autoSendCode = true;
      }
    }

    pushReplacement(
      context,
      '/login',
      LoginPage(
        loadPage: widget.service is SOAService
            ? ({
                required sc,
                required onStateChange,
                required onComplete,
                required onlyThis,
              }) =>
                (widget.service as SOAService).getLoginPage(
                  sc: sc,
                  onStateChange: onStateChange,
                  onComplete: onComplete,
                  onlyThis: onlyThis,
                )
            : widget.service.getLoginPage,
      ),
      pushInto: true,
    );
  }

  Future<void> _logout() async { 
    try {
      await widget.service.logout(notify: true);   
      setState(() {});
      showSuccessToast('退出成功！');
    } catch (e) {
      showErrorToast('退出失败：$e');
    }
  }
}
