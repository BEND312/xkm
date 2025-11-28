import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/entity/button_state.dart';
import 'package:swustmeow/components/login_pages/login_page_base.dart';
import 'package:swustmeow/services/boxes/ykt_box.dart';
import 'package:swustmeow/utils/widget.dart';

import '../../services/global_service.dart';
import '../../utils/common.dart';
import '../../utils/status.dart';
import '../icon_text_field.dart';

class YKTLoginPage extends LoginPageBase {
  const YKTLoginPage({
    super.key,
    required super.sc,
    required super.onStateChange,
    required super.onComplete,
    required super.onlyThis,
  });

  @override
  State<StatefulWidget> createState() => _YKTLoginPageState();
}

class _YKTLoginPageState extends State<YKTLoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  bool _remember = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
    _checkSOALogin();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  void _checkSOALogin() {
    final soaService = GlobalService.soaService;
    if (soaService != null && soaService.isLogin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refresh();
      });
    }
  }

  bool _canUseSOALogin() {
    final soaService = GlobalService.soaService;
    if (soaService == null || !soaService.isLogin) {
      return false;
    }
    
    final soaAccount = soaService.currentAccount;
    if (soaAccount == null) {
      return false;
    }
    
    return true;
  }

  Future<void> _loadRemembered() async {
    final username = YKTBox.get('username') as String?;
    final password = YKTBox.get('password') as String?;
    final remember = (YKTBox.get('remember') as bool?) ?? false;

    if (remember) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refresh(() {
          _remember = remember;
          if (username != null) _usernameController.text = username;
          if (password != null) _passwordController.text = password;
          widget.onStateChange(ButtonStateContainer(ButtonState.ok,
              withCaptcha: widget.sc.withCaptcha, captcha: widget.sc.captcha));
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    validate() {
      final password = _passwordController.text;
      final captcha = _captchaController.text;

      if (password.trim().isEmpty) {
        return ButtonStateContainer(
          ButtonState.dissatisfied,
          message: '请输入密码',
          withCaptcha: widget.sc.withCaptcha,
          captcha: widget.sc.captcha,
        );
      }

      if (widget.sc.withCaptcha == true && captcha.trim().length != 4) {
        return ButtonStateContainer(
          ButtonState.dissatisfied,
          message: '请输入四位验证码',
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

    onChange() {
      final sc = validate();
      widget.onStateChange(sc);
    }

    final checkBoxStyle = context.theme.checkboxStyle.copyWith(
      labelLayoutStyle: context.theme.checkboxStyle.labelLayoutStyle.copyWith(
        labelPadding: EdgeInsets.symmetric(horizontal: 8.0),
        descriptionPadding: EdgeInsets.symmetric(horizontal: 8.0),
        errorPadding: EdgeInsets.symmetric(horizontal: 8.0),
        childPadding: EdgeInsets.zero,
      ),
    );

    return Form(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '登录到西科大一卡通服务',
            style: TextStyle(fontSize: 14),
          ),
          IconTextField(
            icon: FIcon(FAssets.icons.user),
            controller: _usernameController,
            hint: '请输入学号',
            autofocus: false,
            onChange: (_) => onChange(),
            textInputAction: TextInputAction.next,
          ),
          IconTextField.password(
            icon: FIcon(FAssets.icons.lock),
            controller: _passwordController,
            label: null,
            hint: '请输入密码',
            autofocus: false,
            onChange: (_) => onChange(),
            obscureText: !_showPassword,
            suffixBuilder: (context, style, child) {
              return FTappable(
                onPress: () => setState(() => _showPassword = !_showPassword),
                child: FIcon(
                  _showPassword ? FAssets.icons.eye : FAssets.icons.eyeClosed,
                ),
              );
            },
            textInputAction: TextInputAction.done,
          ),
          if (widget.sc.withCaptcha == true)
            CaptchaInput(
              captchaBase64: widget.sc.captcha as String,
              captchaController: _captchaController,
              onChange: onChange,
            ),
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
                  '用于展示一卡通卡片、出示付款码、账单查询等，跳过后无法使用相关功能，可后续登录',
                  style: TextStyle(fontSize: 14),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
          FCheckbox(
            label: const Text('记住账号和密码'),
            description: const Text(
              '下次登录时可自动填充',
              style: TextStyle(fontSize: 12),
            ),
            value: _remember,
            onChange: (value) => setState(() => _remember = value),
            style: checkBoxStyle,
          ),
          Row(
            children: [
              Expanded(child: _buildSubmitButton()),
              const SizedBox(width: 16.0),
              FButton(
                onPress: () => widget.onComplete(),
                label: const Text('跳过'),
                style: FButtonStyle.ghost,
              )
            ],
          ),
          if (_canUseSOALogin()) 
            Row(
              children: [
                Expanded(
                  child: FButton(
                    onPress: () async => await _submit(useSOAAccount: true),
                    label: Text('使用一站式登录'),
                    style: FButtonStyle.secondary,
                  ),
                )
              ],
            ),
        ],
      ).wrap(context: context),
    );
  }

  Widget _buildSubmitButton() {
    final nextStepLabel = widget.onlyThis ? '登录' : '下一步 -->';

    return FButton(
      style: switch (widget.sc.state) {
        ButtonState.ok => FButtonStyle.primary,
        ButtonState.dissatisfied ||
        ButtonState.loading =>
          FButtonStyle.secondary,
        ButtonState.error => FButtonStyle.destructive,
      },
      onPress: () async {
        if (widget.sc.state == ButtonState.ok) {
          await _submit();
        }
      },
      label: Row(
        children: [
          if (widget.sc.state == ButtonState.loading) ...[
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(
              width: 8.0,
            ),
          ],
          widget.sc.state == ButtonState.ok
              ? Text(nextStepLabel)
                  .animate(onPlay: (controller) => controller.repeat())
                  .shimmer(
                      duration: 1.5.seconds,
                      delay: 0.5.seconds,
                      color: Colors.grey)
              : Text(
                  widget.sc.state == ButtonState.loading
                      ? '登录中'
                      : widget.sc.message ?? nextStepLabel,
                )
        ],
      ),
    );
  }

  Future<void> _submit({bool useSOAAccount = false}) async {
    final service = GlobalService.yktService;
    final soaService = GlobalService.soaService;
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (service == null || soaService == null) {
      widget.onStateChange(
        ButtonStateContainer(
          ButtonState.error,
          message: '本地服务未启动，请重启 APP',
          withCaptcha: widget.sc.withCaptcha,
          captcha: widget.sc.captcha,
        ),
      );
      return;
    }

    if (useSOAAccount) {
      final soaAccount = soaService.currentAccount;
      if (soaAccount == null) {
        showErrorToast('无法使用一站式账号登录，请手动登录！');
        widget.onStateChange(ButtonStateContainer(ButtonState.ok));
        return;
      } else {
        username = soaAccount.account;
        password = soaAccount.password.isEmpty ? 'SOA_TGC_LOGIN' : soaAccount.password;
      }
    }

    if (!mounted) {
      return;
    }

    final manualCaptcha =
        widget.sc.withCaptcha == true ? _captchaController.text : null;

    if (username.isEmpty || (password.isEmpty && !useSOAAccount)) {
      showErrorToast('请输入账号和密码');
      return;
    }

    widget.onStateChange(
      ButtonStateContainer(
        ButtonState.loading,
        withCaptcha: widget.sc.withCaptcha,
        captcha: widget.sc.captcha,
      ),
    );

    final result = await service.login(
      username: username,
      password: password,
      remember: _remember,
      manualCaptcha: manualCaptcha,
      useSOATGC: useSOAAccount,
    );

    if (result.status == Status.manualCaptchaRequired) {
      widget.onStateChange(
        ButtonStateContainer(
          ButtonState.dissatisfied,
          message: '请输入验证码',
          withCaptcha: true,
          captcha: result.value,
        ),
      );
      return;
    }

    if (result.status == Status.captchaFailed) {
      widget.onStateChange(
        ButtonStateContainer(
          ButtonState.dissatisfied,
          message: '验证码有误或过期，请重试',
          withCaptcha: true,
          captcha: result.value,
        ),
      );
      setState(() {});
      return;
    }

    if (result.status != Status.ok) {
      widget.onStateChange(
        ButtonStateContainer(
          ButtonState.error,
          message: result.value ?? '未知错误',
          withCaptcha: widget.sc.withCaptcha,
          captcha: widget.sc.captcha,
        ),
      );
      return;
    }

    widget.onStateChange(
      ButtonStateContainer(
        ButtonState.ok,
        withCaptcha: widget.sc.withCaptcha,
        captcha: widget.sc.captcha,
      ),
    );
    widget.onComplete();
  }
}

class CaptchaInput extends StatefulWidget {
  final String captchaBase64;
  final TextEditingController captchaController;
  final Function() onChange;

  const CaptchaInput({
    super.key,
    required this.captchaBase64,
    required this.captchaController,
    required this.onChange,
  });

  @override
  State<StatefulWidget> createState() => _CaptchaInputState();
}

class _CaptchaInputState extends State<CaptchaInput> {
  Widget? _captchaImage;
  String? _cachedBase64;

  @override
  void initState() {
    super.initState();
    update();
  }

  void update() {
    _cachedBase64 = widget.captchaBase64;
    _captchaImage = SizedBox(
      width: 90,
      height: 30,
      child: Image.memory(
        base64Decode(widget.captchaBase64),
        width: 90,
        height: 30,
        key: ValueKey(widget.captchaBase64),
      ),
    );
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.captchaBase64 != _cachedBase64) {
      _refresh(update);
    }

    return Row(
      children: joinGap(
        gap: 8,
        axis: Axis.horizontal,
        widgets: [
          Expanded(
            child: IconTextField(
              controller: widget.captchaController,
              icon: FIcon(FAssets.icons.shield),
              hint: '请输入验证码',
              onChange: (_) => widget.onChange(),
              textInputAction: TextInputAction.done,
            ),
          ),
          _captchaImage!,
        ],
      ),
    );
  }
}
