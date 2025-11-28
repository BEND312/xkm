/*
 * Copyright (c) 2025 BEND
 *
 * This file is a new addition to the project, created as part of secondary development.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/entity/button_state.dart';
import 'package:swustmeow/components/login_pages/login_page_base.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/status.dart';

import '../../data/m_theme.dart';
import '../../services/boxes/soa_box.dart';
import '../../services/boxes/common_box.dart';
import '../../services/global_service.dart';
import '../../services/value_service.dart';
import '../icon_text_field.dart';

class SOASMSLoginPage extends LoginPageBase {
  const SOASMSLoginPage({
    super.key,
    required super.sc,
    required super.onStateChange,
    required super.onComplete,
    required super.onlyThis,
  });

  @override
  State<StatefulWidget> createState() => _SOASMSLoginPageState();
}

class _SOASMSLoginPageState extends State<SOASMSLoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  late AnimationController _agreementController;
  bool _isGettingCode = false;
  bool _isLogging = false;
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _rememberPhone = false;

  @override
  void initState() {
    super.initState();

    _loadRemembered();
    _agreementController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _agreementController.dispose();
    super.dispose();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  Future<void> _loadRemembered() async {
    final phone = SOABox.get('phone') as String?;
    final remember = (SOABox.get('rememberPhone') as bool?) ?? false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh(() {
        _rememberPhone = remember;
        if (remember && phone != null) {
          _phoneController.text = phone;
        }
      });
    });
  }

  Future<void> _getVerificationCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      showErrorToast('请输入手机号');
      return;
    }

    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
      showErrorToast('请输入正确的手机号');
      return;
    }

    setState(() {
      _isGettingCode = true;
    });

    try {
      final api = GlobalService.soaService?.api;
      if (api == null) {
        showErrorToast('服务未初始化');
        return;
      }
      final result = await api.getDynamicCode(phone);
      if (result.status == Status.ok) {
        showSuccessToast(result.value ?? '验证码发送成功');
        _startCountdown();
      } else {
        showErrorToast(result.value ?? '发送验证码失败');
      }
    } catch (e) {
      showErrorToast('发送验证码异常：$e');
    } finally {
      setState(() {
        _isGettingCode = false;
      });
    }
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
        if (_countdown <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    setState(() {
      _isLogging = true;
    });

    widget.onStateChange(
      ButtonStateContainer(
        ButtonState.loading,
        withCaptcha: widget.sc.withCaptcha,
        captcha: widget.sc.captcha,
      ),
    );

    try {

      if (GlobalService.soaService == null) {
        widget.onStateChange(
          ButtonStateContainer(
            ButtonState.error,
            message: '服务未初始化',
            withCaptcha: widget.sc.withCaptcha,
            captcha: widget.sc.captcha,
          ),
        );
        showErrorToast('服务未初始化');
        return;
      }

      final result = await GlobalService.soaService!.loginByPhone(
        phone: phone,
        code: code,
      );
      
      if (result.status == Status.ok) {
        if (_rememberPhone) {
          await SOABox.put('phone', phone);
          await SOABox.put('rememberPhone', true);
        } else {
          await SOABox.delete('phone');
          await SOABox.put('rememberPhone', false);
        }
        
        widget.onStateChange(
          ButtonStateContainer(
            ButtonState.ok,
            withCaptcha: widget.sc.withCaptcha,
            captcha: widget.sc.captcha,
          ),
        );
        showSuccessToast('登录成功');
        widget.onComplete();
      } else {
        widget.onStateChange(
          ButtonStateContainer(
            ButtonState.error,
            message: result.value ?? '短信登录失败',
            withCaptcha: widget.sc.withCaptcha,
            captcha: widget.sc.captcha,
          ),
        );
        showErrorToast(result.value ?? '短信登录失败');
      }
    } catch (e) {
      widget.onStateChange(
        ButtonStateContainer(
          ButtonState.error,
          message: '登录异常：$e',
          withCaptcha: widget.sc.withCaptcha,
          captcha: widget.sc.captcha,
        ),
      );
      showErrorToast('登录异常：$e');
    } finally {
      setState(() {
        _isLogging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    validate() {
      final phone = _phoneController.text.trim();
      final code = _codeController.text.trim();

      if (phone.isEmpty) {
        return ButtonStateContainer(
          ButtonState.dissatisfied,
          message: '请输入手机号',
          withCaptcha: widget.sc.withCaptcha,
          captcha: widget.sc.captcha,
        );
      }

      if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(phone)) {
        return ButtonStateContainer(
          ButtonState.dissatisfied,
          message: '请输入正确的手机号',
          withCaptcha: widget.sc.withCaptcha,
          captcha: widget.sc.captcha,
        );
      }

      if (code.isEmpty) {
        return ButtonStateContainer(
          ButtonState.dissatisfied,
          message: '请输入验证码',
          withCaptcha: widget.sc.withCaptcha,
          captcha: widget.sc.captcha,
        );
      }

      if (code.length != 6) {
        return ButtonStateContainer(
          ButtonState.dissatisfied,
          message: '请输入6位验证码',
          withCaptcha: widget.sc.withCaptcha,
          captcha: widget.sc.captcha,
        );
      }

      return ButtonStateContainer(
        ButtonState.ok,
        withCaptcha: widget.sc.withCaptcha,
        captcha: widget.sc.captcha,
      );
    }

    final state = validate();
    widget.onStateChange(state);

    final checkBoxStyle = context.theme.checkboxStyle.copyWith(
      labelLayoutStyle: context.theme.checkboxStyle.labelLayoutStyle.copyWith(
        labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        descriptionPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        errorPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        childPadding: const EdgeInsets.all(0),
      ),
    );

    return Form(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '登录到西科大一站式服务',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          IconTextField(
            icon: FIcon(FAssets.icons.smartphone),
            controller: _phoneController,
            hint: '请输入手机号',
            autofocus: false,
            onChange: (_) => _refresh(),
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          IconTextField(
            icon: FIcon(FAssets.icons.shield),
            controller: _codeController,
            hint: '请输入6位验证码',
            autofocus: false,
            onChange: (_) => _refresh(),
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.number,
            suffixBuilder: (context, style, child) {
              return FTappable(
                onPress: _countdown > 0 || _isGettingCode ? null : _getVerificationCode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    _isGettingCode
                        ? '发送中...'
                        : _countdown > 0
                            ? '${_countdown}s'
                            : '获取验证码',
                    style: TextStyle(
                      fontSize: 14,
                      color: _countdown > 0 || _isGettingCode
                          ? MTheme.primaryText
                          : MTheme.primary2,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(0, 4),
                child: FIcon(
                  FAssets.icons.info,
                  size: 16,
                  alignment: Alignment.centerRight,
                  allowDrawingOutsideViewBox: true,
                ),
              ),
              const SizedBox(
                width: 8.0,
              ),
              const Expanded(
                child: Text(
                  '用于课表获取和账号统一管理',
                  style: TextStyle(fontSize: 14),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FCheckbox(
            label: const Text('记住手机号'),
            description: const Text(
              '下次登录时可自动填充',
              style: TextStyle(fontSize: 12),
            ),
            value: _rememberPhone,
            onChange: (value) => setState(() => _rememberPhone = value),
            style: checkBoxStyle,
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FButton(
              style: state.state == ButtonState.ok
                  ? FButtonStyle.primary
                  : FButtonStyle.secondary,
              onPress: state.state == ButtonState.ok && !_isLogging
                  ? _login
                  : null,
              label: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLogging) ...[
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _isLogging 
                        ? '登录中...' 
                        : (widget.onlyThis ? '登录' : '下一步'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (ValueService.cacheSuccess)
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: () async {
                      await CommonBox.put('skipLoginWithCache', true);
                      widget.onComplete();
                    },
                    label: Text('使用本地课表缓存并跳过登录'),
                    style: FButtonStyle.secondary,
                  ),
                )
              ],
            ),
        ],
      ),
    );
  }
}