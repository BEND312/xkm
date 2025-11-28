import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/entity/button_state.dart';
import 'package:swustmeow/components/login_pages/login_page_base.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/widget.dart';

import '../../services/boxes/apartment_box.dart';
import '../../services/global_service.dart';
import '../../utils/status.dart';
import '../icon_text_field.dart';

class ApartmentLoginPage extends LoginPageBase {
  const ApartmentLoginPage({
    super.key,
    required super.sc,
    required super.onStateChange,
    required super.onComplete,
    required super.onlyThis,
  });

  @override
  State<StatefulWidget> createState() => _ApartmentLoginPageState();
}

class _ApartmentLoginPageState extends State<ApartmentLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _remember = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _loadRemembered();
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  Future<void> _loadRemembered() async {
    final username = ApartmentBox.get('username') as String?;
    final password = ApartmentBox.get('password') as String?;
    final remember = (ApartmentBox.get('remember') as bool?) ?? false;

    if (remember) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refresh(() {
          _remember = remember;
          if (username != null) _usernameController.text = username;
          if (password != null) _passwordController.text = password;
          widget.onStateChange(const ButtonStateContainer(ButtonState.ok));
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    validate() {
      final password = _passwordController.text;

      if (password.trim().isEmpty) {
        return const ButtonStateContainer(
          ButtonState.dissatisfied,
          message: '请输入密码',
        );
      }

      return const ButtonStateContainer(ButtonState.ok);
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
            '登录到西科大公寓服务',
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
                  '用于宿舍电费、二维码等获取，跳过后无法使用相关功能，可后续手动登录',
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
          Row(
            children: [
              Expanded(
                child: FButton(
                  onPress: () async => await _submit(useSOAAccount: true),
                  label: Text('使用一站式账号一键登录'),
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
    widget.onStateChange(const ButtonStateContainer(ButtonState.loading));
    String username = _usernameController.value.text;
    String password = _passwordController.value.text;

    if (useSOAAccount) {
      final soaAccount = GlobalService.soaService?.currentAccount;
      if (soaAccount == null) {
        showErrorToast('无法使用一站式账号登录，请手动登录！');
        widget.onStateChange(ButtonStateContainer(ButtonState.ok));
        return;
      } else {
        username = soaAccount.account;
        password = soaAccount.password;
      }
    }
    

    if (GlobalService.apartmentService == null) {

      widget.onStateChange(const ButtonStateContainer(ButtonState.error,
          message: '本地服务未启动，请重启 APP'));
      return;
    }

    final result = await GlobalService.apartmentService!
        .login(username: username, password: password, remember: _remember);
    if (result.status == Status.ok) {
      widget
          .onStateChange(const ButtonStateContainer(ButtonState.dissatisfied));
      widget.onComplete();
    } else {
      widget.onStateChange(ButtonStateContainer(ButtonState.error,
          message: result.value ?? '未知错误'));
    }
  }
}
