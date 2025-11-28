import 'package:flutter/material.dart';
import 'package:swustmeow/api/chaoxing_api.dart';
import 'package:swustmeow/components/login_pages/chaoxing_login_page.dart';
import 'package:swustmeow/entity/chaoxing/chaoxing_course.dart';
import 'package:swustmeow/entity/chaoxing/chaoxing_exam.dart';
import 'package:swustmeow/entity/chaoxing/chaoxing_homework.dart';
import 'package:swustmeow/services/account/account_service.dart';
import 'package:swustmeow/services/boxes/chaoxing_box.dart';
import 'package:swustmeow/services/color_service.dart';

import '../../entity/button_state.dart';
import '../../entity/account.dart';
import '../../utils/color.dart';
import '../../utils/status.dart';

class ChaoXingService extends AccountService<ChaoXingLoginPage> {
  ChaoXingApiService? _api;

  @override
  String get name => '超星学习通';

  @override
  Account? get currentAccount => ChaoXingBox.get('account') as Account?;

  @override
  List<Account> get savedAccounts =>
      (ChaoXingBox.get('accounts') as List<dynamic>? ?? []).cast();

  @override
  bool get isLogin =>
      (((ChaoXingBox.get('isLogin') as bool?) ?? false) &&
          currentAccount != null);

  @override
  ValueNotifier<bool> isLoginNotifier = ValueNotifier(
      (ChaoXingBox.get('isLogin') as bool? ?? false));

  @override
  Color get color =>
      getColorFromPaletteWithStringAndBrightness('chaoxing') ??
      ColorService.defaultChaoXingColor;

  @override
  ChaoXingLoginPage getLoginPage({
    required ButtonStateContainer sc,
    required Function(ButtonStateContainer sc) onStateChange,
    required Function({bool toEnd}) onComplete,
    required bool onlyThis,
  }) =>
      ChaoXingLoginPage(
          sc: sc,
          onStateChange: onStateChange,
          onComplete: onComplete,
          onlyThis: onlyThis);

  @override
  Future<void> init() async {
    _api = ChaoXingApiService();
    await _api?.init();
  }

  /// 登录到超星学习通
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
      username = ChaoXingBox.get('username');
      password = ChaoXingBox.get('password');
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
    await ChaoXingBox.put('isLogin', true);
    await ChaoXingBox.put('username', username);
    await ChaoXingBox.put('password', password);
    await ChaoXingBox.put('remember', remember);

    final account = Account(account: username, password: password);
    await ChaoXingBox.put('account', account);
    final accounts = savedAccounts.where((a) => a.equals(account)).isEmpty
        ? [account, ...savedAccounts]
        : savedAccounts;
    await ChaoXingBox.put('accounts', accounts);

    return result!;
  }

  /// 退出登录
  @override
  Future<void> logout({required bool notify}) async {
    if (notify) {
      isLoginNotifier.value = false;
    }

    await ChaoXingBox.delete('isLogin');
    await ChaoXingBox.delete('account');
    await ChaoXingBox.clearCache();
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
    await ChaoXingBox.put('accounts', savedAccounts);
    if (currentAccount?.equals(account) == true) {
      await logout(notify: true);
    }
  }

  /// 获取所有课程的列表
  ///
  /// 如果获取成功，返回一个 [ChaoXingCourse] 的列表的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
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

  /// 获取所有的作业列表
  ///
  /// 如果获取成功，返回一个 [ChaoXingHomework] 的列表的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<dynamic>> getHomeworks(ChaoXingCourse course) async {
    if (!isLogin) {
      return const StatusContainer(Status.notAuthorized, '未登录');
    }

    final result = await _api?.getHomeworks(course);

    if (result == null || result.status != Status.ok) {
      final r = await login();
      if (r.status != Status.ok) {
        await logout(notify: true);
        return const StatusContainer(Status.notAuthorized, '登录状态失效');
      }

      return await getCourseList();
    }

    return result;
  }

  /// 获取所有的考试列表
  ///
  /// 如果获取成功，返回一个 [ChaoXingExam] 的列表的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<dynamic>> getExams(ChaoXingCourse course) async {
    if (!isLogin) {
      return const StatusContainer(Status.notAuthorized, '未登录');
    }

    final result = await _api?.getExams(course);

    if (result == null || result.status != Status.ok) {
      final r = await login();
      if (r.status != Status.ok) {
        await logout(notify: true);
        return const StatusContainer(Status.notAuthorized, '登录状态失效');
      }

      return await getCourseList();
    }

    return result;
  }
}
