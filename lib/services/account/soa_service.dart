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
import 'package:swustmeow/api/soa_api.dart';
import 'package:swustmeow/components/login_pages/soa_sms_login_page.dart';
import 'package:swustmeow/entity/soa/exam/exam_schedule.dart';
import 'package:swustmeow/entity/soa/leave/daily_leave_display.dart';
import 'package:swustmeow/entity/soa/leave/daily_leave_options.dart';
import 'package:swustmeow/entity/soa/course/optional_course.dart';
import 'package:swustmeow/entity/soa/course/optional_task_type.dart';
import 'package:swustmeow/entity/soa/score/points_data.dart';
import 'package:swustmeow/entity/soa/evaluation_paper.dart';
import 'package:swustmeow/services/account/account_service.dart';
import 'package:swustmeow/services/color_service.dart';
import 'package:swustmeow/services/value_service.dart';

import '../../entity/button_state.dart';
import '../../entity/account.dart';
import '../../entity/soa/course/courses_container.dart';
import '../../entity/soa/score/course_score.dart';
import '../../utils/color.dart';
import '../../utils/status.dart';
import '../boxes/common_box.dart';
import '../boxes/course_box.dart';
import '../boxes/soa_box.dart';
import '../global_service.dart';

class SOAService extends AccountService<SOASMSLoginPage> {
  SOAApiService? api;

  @override
  String get name => '一站式服务';

  @override
  Account? get currentAccount => SOABox.get('account') as Account?;

  @override
  List<Account> get savedAccounts =>
      (SOABox.get('accounts') as List<dynamic>? ?? []).cast();

  @override
  bool get isLogin =>
      (((SOABox.get('isLogin') as bool?) ?? false) && currentAccount != null);

  @override
  ValueNotifier<bool> isLoginNotifier = ValueNotifier(
      (SOABox.get('isLogin') as bool? ?? false));

  @override
  Color get color =>
      getColorFromPaletteWithStringAndBrightness('soa') ??
      ColorService.defaultSoaColor;

  @override
  SOASMSLoginPage getLoginPage({
    required ButtonStateContainer sc,
    required Function(ButtonStateContainer sc) onStateChange,
    required Function({bool toEnd}) onComplete,
    required bool onlyThis,
  }) =>
      SOASMSLoginPage(
          sc: sc,
          onStateChange: onStateChange,
          onComplete: onComplete,
          onlyThis: onlyThis);

  @override
  Future<void> init() async {
    api = SOAApiService();
    await api?.init();
  }

  /// 登录到一站式系统并获取凭证 (TGC)
  ///
  /// 若登录成功，返回包含 `TGC` 字符串的状态容器；
  /// 否则，返回包含错误信息字符串的状态容器。
  @override
  Future<StatusContainer<String>> login({
    String? username,
    String? password,
    int retries = 3,
    bool remember = true,
    StatusContainer? lastStatusContainer,
    String? manualCaptcha,
  }) async {
    if (retries == 0) {
      return StatusContainer(lastStatusContainer?.status ?? Status.fail,
          lastStatusContainer?.value.$2 ?? '服务器错误，请稍后再试');
    }
    if (username == null || password == null) {
      username = SOABox.get('username') as String?;
      password = SOABox.get('password') as String?;
    }

    if (username == null || password == null) {
      return const StatusContainer(Status.fail, '内部参数错误');
    }

    final loginResult = api != null
        ? await SOAApiService.loginToSOA(
            dio: api!.dio,
            username: username,
            password: password,
            manualCaptcha: manualCaptcha,
            captchaRetry: manualCaptcha != null ? 1 : 3,
          )
        : null;

    if (loginResult != null &&
        (loginResult.status == Status.manualCaptchaRequired ||
            loginResult.status == Status.captchaFailed)) {
      return StatusContainer(loginResult.status, loginResult.value?.$2);
    }

    if (loginResult == null || loginResult.status == Status.fail) {
      return await login(
        username: username,
        password: password,
        retries: retries - 1,
        remember: remember,
        lastStatusContainer: loginResult,
        manualCaptcha: manualCaptcha,
      );
    }

    await GlobalService.webViewCookieService?.deleteCookieSet('soa');
    final tgc = loginResult.value?.$2;
    isLoginNotifier.value = true;

    await SOABox.put('isLogin', true);
    await SOABox.put('tgc', tgc);
    await SOABox.put('username', username);
    await SOABox.put('password', password);
    await SOABox.put('remember', remember);

    final account = Account(account: username, password: password);
    await SOABox.put('account', account);
    final accounts = savedAccounts.where((a) => a.equals(account)).isEmpty
        ? [account, ...savedAccounts]
        : savedAccounts;
    await SOABox.put('accounts', accounts);
    await CommonBox.delete('skipLoginWithCache');
    await SOABox.clearCache();

    return StatusContainer(Status.ok, tgc);
  }

  /// 短信登录到一站式系统
  ///
  /// [phone] 手机号
  /// [code] 验证码
  /// 返回状态容器，成功时包含登录结果
  Future<StatusContainer<String>> loginByPhone({
    required String phone,
    required String code,
  }) async {
    if (api == null) {
      return const StatusContainer(Status.fail, 'API服务未初始化');
    }

    final loginResult = await api!.loginByPhone(phone, code);
    
    if (loginResult.status != Status.ok) {
      return StatusContainer(loginResult.status, loginResult.value);
    }

    await GlobalService.webViewCookieService?.deleteCookieSet('soa');
    final tgc = loginResult.value;
    isLoginNotifier.value = true;

    await SOABox.put('isLogin', true);
    await SOABox.put('tgc', tgc);
    await SOABox.put('username', phone);
    await SOABox.put('password', ''); // 短信登录没有密码
    await SOABox.put('remember', false); // 短信登录不记住密码

    final account = Account(
      account: phone, 
      password: '', 
      username: '$phone (短信登录)'
    );
    await SOABox.put('account', account);
    final existingAccountIndex = savedAccounts.indexWhere((a) => a.account == phone);
    List<Account> accounts;
    
    if (existingAccountIndex >= 0) {
      accounts = [...savedAccounts];
      accounts[existingAccountIndex] = account;
    } else {
      accounts = [account, ...savedAccounts];
    }
    
    await SOABox.put('accounts', accounts);
    await CommonBox.delete('skipLoginWithCache');
    await SOABox.clearCache();
    return StatusContainer(Status.ok, tgc);
  }

  @override
  Future<void> logout({required bool notify}) async {
    if (notify) {
      isLoginNotifier.value = false;
    }

    final keys = ['isLogin', 'tgc', 'account'];
    for (final key in keys) {
      await SOABox.delete(key);
    }
    await SOABox.clearCache();
    await api?.deleteCookies();
    await GlobalService.webViewCookieService?.deleteCookieSet('soa');
  }

  @override
  Future<StatusContainer<dynamic>> switchTo(Account account) async {
    await SOABox.clearCache();
    await CourseBox.clearCache();
    ValueService.coursesContainers = [];
    ValueService.currentCoursesContainer.value = null;
    ValueService.todayCourses = [];
    ValueService.nextCourse = null;
    ValueService.currentCourse = null;
    await api?.deleteCookies();
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
    await SOABox.put('accounts', savedAccounts);
    if (currentAccount?.equals(account) == true) {
      await logout(notify: true);
    }
  }

  /// 检查是否登录
  ///
  /// 如果已登录，返回一个带有 TGC 凭证字符串的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<String>> checkLogin() async {
    final tgc = SOABox.get('tgc') as String?;
    if (tgc == null) {
      return const StatusContainer(Status.notAuthorized, '未登录');
    }
    return StatusContainer(Status.ok, tgc);
  }

  /// 获取普通课和选课课程表
  ///
  /// 若获取成功，返回一个 [CoursesContainer] 的列表的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getCourseTables({int retries = 1}) async {
    if (retries == 0) {
      return StatusContainer(Status.fail, '获取课表失败');
    }

    final tgc = await checkLogin();
    if (tgc.status != Status.ok) return tgc;

    final result = await api?.getCourseTables(tgc.value!);
    if (result?.status == Status.notAuthorized && retries > 0) {
      await login();
      return await getCourseTables(retries: retries - 1);
    }

    if (result == null ||
        (result.status != Status.ok &&
            result.status != Status.okWithToast &&
            result.status != Status.partiallyOkWithToast)) {
      return result ?? StatusContainer(Status.fail, '内部错误');
    }

    List<CoursesContainer> r = (result.value as List<dynamic>).cast();
    await CourseBox.put('courseTables', r);
    return StatusContainer(Status.ok, r);
  }

  /// 根据类别获取选课的课程列表
  ///
  /// 若获取成功，返回一个 [OptionalCourse] 的列表的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getOptionalCourses(OptionalTaskType taskType,
      {int retries = 3}) async {
    final tgc = await checkLogin();
    if (tgc.status != Status.ok) return tgc;

    final result = await api?.getOptionalCourses(tgc.value!, taskType);
    if (result?.status == Status.notAuthorized && retries > 0) {
      await login();
      return await getOptionalCourses(taskType, retries: retries - 1);
    }

    if (result == null || result.status != Status.ok) {
      return result ?? StatusContainer(Status.fail, '内部错误');
    }

    List<OptionalCourse> r = (result.value as List<dynamic>).cast();
    await SOABox.put('optionalCourses', r);
    return StatusContainer(Status.ok, r);
  }

  /// 获取所有的考试
  ///
  /// 若获取成功，返回一个 [ExamSchedule] 的列表的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getExams({int retries = 3}) async {
    final tgc = await checkLogin();
    if (tgc.status != Status.ok) return tgc;

    final result = await api?.getExams(tgc.value!);
    if (result?.status == Status.notAuthorized && retries > 0) {
      await login();
      return await getExams(retries: retries - 1);
    }

    if (result == null || result.status != Status.ok) {
      return result ?? StatusContainer(Status.fail, '内部错误');
    }

    List<ExamSchedule> r = (result.value as List<dynamic>).cast();
    await SOABox.put('examSchedules', r);
    return StatusContainer(Status.ok, r);
  }

  /// 获取所有的考试成绩
  ///
  /// 若获取成功，返回一个 [CourseScore] 的列表的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getScores({int retries = 3}) async {
    final tgc = await checkLogin();
    if (tgc.status != Status.ok) return tgc;

    final result = await api?.getScores(tgc.value!);
    if (result?.status == Status.notAuthorized && retries > 0) {
      await login();
      return await getScores(retries: retries - 1);
    }

    if (result == null || result.status != Status.ok) {
      return result ?? StatusContainer(Status.fail, '内部错误');
    }

    List<CourseScore> r = (result.value as List<dynamic>).cast();
    await SOABox.put('courseScores', r);
    return StatusContainer(Status.ok, r);
  }

  /// 获取学分、绩点数据
  ///
  /// 如果获取成功，返回一个带有 [PointsData] 的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<dynamic>> getPointsData({int retries = 3}) async {
    final tgc = await checkLogin();
    if (tgc.status != Status.ok) return tgc;

    final result = await api?.getPointsData(tgc.value!);
    if (result?.status == Status.notAuthorized && retries > 0) {
      await login();
      return await getPointsData(retries: retries - 1);
    }

    if (result == null || result.status != Status.ok) {
      return result ?? StatusContainer(Status.fail, '内部错误');
    }

    PointsData r = result.value as PointsData;
    await SOABox.put('pointsData', r);
    return StatusContainer(Status.ok, r);
  }

  /// 获取已有日常请假的信息
  ///
  /// 若获取成功，返回一个 [DailyLeaveOptions] 的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getDailyLeaveInformation(String leaveId,
      {int retries = 3}) async {
    final tgc = await checkLogin();
    if (tgc.status != Status.ok) return tgc;

    final result = await api?.getDailyLeaveInformation(tgc.value!, leaveId);
    if (result?.status == Status.notAuthorized && retries > 0) {
      await login();
      return await getDailyLeaveInformation(leaveId, retries: retries - 1);
    }

    if (result == null || result.status != Status.ok) {
      return result ?? StatusContainer(Status.fail, '内部错误');
    }

    return result;
  }

  /// 获取所有的日常请假
  ///
  /// 若获取成功，返回一个 [DailyLeaveDisplay] 的列表的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getDailyLeaves({int retries = 3}) async {
    final tgc = await checkLogin();
    if (tgc.status != Status.ok) return tgc;

    final result = await api?.getDailyLeaves(tgc.value!);
    if (result?.status == Status.notAuthorized && retries > 0) {
      await login();
      return await getDailyLeaves(retries: retries - 1);
    }

    if (result == null || result.status != Status.ok) {
      return result ?? StatusContainer(Status.fail, '内部错误');
    }

    return result;
  }

  Future<StatusContainer<List<EvaluationPaper>>> getEvaluationPaperList({
    int retries = 3,
  }) async {
    final tgc = await checkLogin();
    if (tgc.status != Status.ok) {
      return StatusContainer(tgc.status, []);
    }

    try {
      final result = await api?.getEvaluationPaperList();
      if (result == null) {
        return const StatusContainer(Status.fail, []);
      }

      return StatusContainer(Status.ok, result);
    } catch (e) {
      if (retries > 0) {
        await login();
        return await getEvaluationPaperList(retries: retries - 1);
      }
      return StatusContainer(Status.fail, []);
    }
  }

  Future<StatusContainer<bool>> evaluateOne(
    Map<String, dynamic> evaluation,
    String courseComment,
    int value, {
    int retries = 3,
  }) async {
    final tgc = await checkLogin();
    if (tgc.status != Status.ok) {
      return const StatusContainer(Status.fail, false);
    }

    try {
      final result = await api?.evaluateOne(evaluation, courseComment, value);
      if (result == null) {
        return const StatusContainer(Status.fail, false);
      }

      return StatusContainer(Status.ok, result);
    } catch (e) {
      if (retries > 0) {
        await login();
        return await evaluateOne(evaluation, courseComment, value,
            retries: retries - 1);
      }
      return const StatusContainer(Status.fail, false);
    }
  }

  Future<StatusContainer<Map<String, dynamic>>> evaluateAll({
    String courseComment = "无",
    int value = 1,
    int retries = 3,
  }) async {
    final tgc = await checkLogin();
    if (tgc.status != Status.ok) {
      return StatusContainer(tgc.status, {
        'success': false,
        'message': '未登录',
        'total': 0,
        'completed': 0,
      });
    }

    try {
      final result = await api?.evaluateAll(
        courseComment: courseComment,
        value: value,
      );
      
      if (result == null) {
        return StatusContainer(Status.fail, {
          'success': false,
          'message': '评价失败',
          'total': 0,
          'completed': 0,
        });
      }

      return StatusContainer(Status.ok, result);
    } catch (e) {
      if (retries > 0) {
        await login();
        return await evaluateAll(
          courseComment: courseComment,
          value: value,
          retries: retries - 1,
        );
      }
      return StatusContainer(Status.fail, {
        'success': false,
        'message': '评价失败: $e',
        'total': 0,
        'completed': 0,
      });
    }
  }
}

