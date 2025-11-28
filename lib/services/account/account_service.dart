import 'package:flutter/cupertino.dart';
import 'package:swustmeow/components/login_pages/login_page_base.dart';
import 'package:swustmeow/entity/account.dart';
import 'package:swustmeow/utils/status.dart';

import '../../entity/button_state.dart';

abstract class AccountService<T extends LoginPageBase> {
  /// 账号服务名称
  String get name;

  /// 当前账号
  Account? get currentAccount;

  /// 所有已保存过的的账号
  List<Account> get savedAccounts;

  /// 是否已登录
  bool get isLogin;

  /// 是否已登录的 [ValueNotifier]
  ValueNotifier<bool> get isLoginNotifier;

  /// 专用颜色
  Color get color;

  /// 初始化
  Future<void> init();

  /// 登录
  ///
  /// 返回一个是否登录成功的状态容器。
  Future<StatusContainer<dynamic>> login({
    String? username,
    String? password,
    int retries = 3,
    bool remember = false,
    StatusContainer? lastStatusContainer,
  });

  /// 退出登录
  Future<void> logout({required bool notify});

  /// 切换到另一个账号
  Future<StatusContainer<dynamic>> switchTo(Account account);

  /// 删除一个账号
  Future<void> deleteAccount(Account account);

  /// 获取登录页面实例
  T getLoginPage({
    required ButtonStateContainer sc,
    required Function(ButtonStateContainer sc) onStateChange,
    required Function({bool toEnd}) onComplete,
    required bool onlyThis,
  });
}
