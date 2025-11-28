import 'package:flutter/material.dart';
import 'package:swustmeow/api/duifene_api.dart';
import 'package:swustmeow/components/login_pages/duifene_login_page.dart';
import 'package:swustmeow/entity/duifene/duifene_course.dart';
import 'package:swustmeow/entity/duifene/duifene_homework.dart';
import 'package:swustmeow/entity/duifene/sign/sign_types/duifene_sign_base.dart';
import 'package:swustmeow/services/account/account_service.dart';
import 'package:swustmeow/services/color_service.dart';

import '../../entity/button_state.dart';
import '../../entity/account.dart';
import '../../entity/duifene/duifene_test.dart';
import '../../utils/color.dart';
import '../../utils/status.dart';
import '../boxes/duifene_box.dart';
import '../global_service.dart';

class DuiFenEService extends AccountService<DuiFenELoginPage> {
  DuiFenEApiService? _api;

  @override
  String get name => '对分易';

  @override
  Account? get currentAccount => DuiFenEBox.get('account') as Account?;

  @override
  List<Account> get savedAccounts =>
      (DuiFenEBox.get('accounts') as List<dynamic>? ?? []).cast();

  @override
  bool get isLogin =>
      (((DuiFenEBox.get('isLogin') as bool?) ?? false) &&
          currentAccount != null);

  @override
  ValueNotifier<bool> isLoginNotifier = ValueNotifier(
      (DuiFenEBox.get('isLogin') as bool? ?? false));

  @override
  Color get color =>
      getColorFromPaletteWithStringAndBrightness('duifene') ??
      ColorService.defaultDuifeneColor;

  @override
  DuiFenELoginPage getLoginPage({
    required ButtonStateContainer sc,
    required Function(ButtonStateContainer sc) onStateChange,
    required Function({bool toEnd}) onComplete,
    required bool onlyThis,
  }) =>
      DuiFenELoginPage(
          sc: sc,
          onStateChange: onStateChange,
          onComplete: onComplete,
          onlyThis: onlyThis);

  @override
  Future<void> init() async {
    _api = DuiFenEApiService();
    await _api?.init();
    await checkLogin();
    
  }

  Future<bool> checkLogin() async {
    final flag = await _api?.getIsLogin() ?? false;
    
    if (!flag) {
      final username = DuiFenEBox.get('username');
      final password = DuiFenEBox.get('password');

      if (username != null && password != null && password.toString().isNotEmpty) {
        final result = await login();
        final success = result.status == Status.ok;
        
        isLoginNotifier.value = success;
        await DuiFenEBox.put('isLogin', success);
        return success;
      }
      isLoginNotifier.value = false;
      await DuiFenEBox.put('isLogin', false);
      return false;
    } else {
      isLoginNotifier.value = true;
      await DuiFenEBox.put('isLogin', true);
      return true;
    }
  }

  /// 登录到对分易
  ///
  /// 返回一个是否登录成功的状态容器。
  @override
  Future<StatusContainer> login({
    String? username,
    String? password,
    int retries = 3,
    bool remember = true,
    StatusContainer? lastStatusContainer,
  }) async {
    
    if (retries == 0) {
      return StatusContainer(
          Status.fail, lastStatusContainer?.value ?? '服务器错误，请稍后再试');
    }

    if (username == null || password == null) {
      username = DuiFenEBox.get('username');
      password = DuiFenEBox.get('password');
      
    }

    if (username == null || password == null) {
      return const StatusContainer(Status.notAuthorized);
    }

    final result = await _api?.login(username, password);
    final status = result?.status;

    if (status == null || status != Status.ok) {
      return await login(
        username: username,
        password: password,
        retries: retries - 1,
        remember: remember,
        lastStatusContainer: result,
      );
    }

    isLoginNotifier.value = true;
    await DuiFenEBox.put('isLogin', true);
    await DuiFenEBox.put('username', username);
    await DuiFenEBox.put('password', password);
    await DuiFenEBox.put('remember', remember);

    final account = Account(account: username, password: password);
    await DuiFenEBox.put('account', account);
    final accounts = savedAccounts.where((a) => a.equals(account)).isEmpty
        ? [account, ...savedAccounts]
        : savedAccounts;
    await DuiFenEBox.put('accounts', accounts);
    await GlobalService.loadDuiFenECourses();
    return result!;
  }

  /// 退出登录
  @override
  Future<void> logout({required bool notify}) async {
    if (notify) {
      isLoginNotifier.value = false;
    }

    await DuiFenEBox.delete('isLogin');
    await DuiFenEBox.delete('account');
    await DuiFenEBox.clearCache();
    await _api?.deleteCookies();
  }

  @override
  Future<StatusContainer<dynamic>> switchTo(Account account) async {
    await logout(notify: true);
    final result =
        await login(username: account.account, password: account.password);
    if (result.status == Status.ok) {
      isLoginNotifier.value = true;
    }
    return result;
  }

  @override
  Future<void> deleteAccount(Account account) async {
    savedAccounts.removeWhere((a) => a.equals(account));
    await DuiFenEBox.put('accounts', savedAccounts);
    if (currentAccount?.equals(account) == true) {
      await logout(notify: true);
    }
  }

  /// 获取课程名称列表
  ///
  /// 若中途遇到异常，返回错误信息字符串的状态容器；
  /// 否则正常返回 [DuiFenECourse] 的列表的状态容器。
  Future<StatusContainer<dynamic>> getCourseList([bool retry = true]) async {
    if (!isLogin) {
      return const StatusContainer(Status.notAuthorized, '未登录');
    }

    final result = await _api?.getCourseList();

    if ((result == null || result.status != Status.ok) && retry) {
      final r = await login();
      if (r.status != Status.ok) {
        await logout(notify: true);
        return const StatusContainer(Status.notAuthorized, '登录状态失效');
      }

      return await getCourseList();
    }

    return result ?? StatusContainer(Status.fail, '获取失败');
  }

  /// 检查是否有签到，返回一个签到信息
  Future<StatusContainer<DuiFenESignBase>> checkSignIn(
      DuiFenECourse course) async {
    if (_api == null) return StatusContainer(Status.fail);
    return await _api!.checkSignIn(course);
  }

  /// 签到码签到
  ///
  /// 返回一个带有消息的字符串状态容器。
  Future<StatusContainer<String>> signInWithSignCode(String signCode) async {
    final result = await _api?.signInWithSignCode(signCode);
    return result ?? StatusContainer(Status.fail, '内部服务错误');
  }

  /// 定位签到
  ///
  /// 返回一个带有消息的字符串状态容器。
  Future<StatusContainer<String>> signInWithLocation(
      double longitude, double latitude) async {
    final result = await _api?.signInWithLocation(longitude, latitude);
    return result ?? StatusContainer(Status.fail, '内部服务错误');
  }

  /// 获取在线练习
  ///
  /// 返回一个带有 [DuiFenETest] 的列表的状态容器。
  Future<StatusContainer<List<DuiFenETest>>> getTests(
      DuiFenECourse course) async {
    final result = await _api?.getTests(course);
    if (result == null) return const StatusContainer(Status.fail);
    return result;
  }

  /// 获取所有作业
  ///
  /// 返回一个带有 [DuiFenEHomework] 的列表的状态容器。
  Future<StatusContainer<List<DuiFenEHomework>>> getHomeworks(
      DuiFenECourse course) async {
    final result = await _api?.getHomeworks(course);
    if (result == null) return const StatusContainer(Status.fail);
    return result;
  }
}
