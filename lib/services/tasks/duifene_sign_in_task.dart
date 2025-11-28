import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive/hive.dart';
import 'package:swustmeow/api/duifene_api.dart';
import 'package:swustmeow/entity/duifene/duifene_course.dart';
import 'package:swustmeow/entity/duifene/sign/duifene_sign_in_status.dart';
import 'package:swustmeow/entity/duifene/sign/sign_types/duifene_location_sign.dart';
import 'package:swustmeow/entity/duifene/sign/sign_types/duifene_sign_code_sign.dart';
import 'package:swustmeow/services/tasks/notification_manager.dart';
import 'package:swustmeow/utils/status.dart';
import '../../entity/duifene/sign/sign_types/duifene_sign_base.dart';
import 'background_task.dart';

class DuiFenESignInTask extends BackgroundTask {
  static const _name = '对分易辅助签到';
  static final _notificationManager =
      NotificationManager(name: _name, notificationId: 924986341);

  // static const threshold = 0.8;
  static DuiFenESignInStatus _status = DuiFenESignInStatus.initializing;

  static DuiFenECourse? _currentCourse;
  static DuiFenESignBase? _currentSignInContainer;
  static int _signCount = 0;
  static DuiFenEApiService? duifeneService;

  // static String? _term;
  // static List<CourseEntry> _entries = [];
  static List<DuiFenECourse> _courses = [];
  static final List<String> _signedId = [];
  static bool _isSignInNotificationEnabled = true;

  DuiFenESignInTask()
      : super(name: _name, duration: const Duration(milliseconds: 3000)) {
    _notificationManager.configureNotification();
  }

  Future<Box> get _box async => await Hive.openBox('duifeneBox');

  @override
  Future<bool> get shouldAutoStart async {
    return ((await _box).get('enableAutomaticSignIn') as bool?) ?? false;
  }

  // Future<bool> _checkCurrentCourse(
  //     ServiceInstance service, bool enableNotification) async {
  //   if (duifeneService == null) return false;
  //
  //   // final isLogin = await duifeneService!.getIsLogin();
  //   // if (!isLogin) {
  //   //   _status = DuiFenESignInStatus.notAuthorized;
  //   //   final box = await _box;
  //   //   await box.put('enableAutomaticSignIn', false);
  //   //   await box.put('isLogin', false);
  //   //   _notificationManager.showNotification(
  //   //     enabled: enableNotification,
  //   //     content: '登录状态失效，请重新登录',
  //   //     enableVibration: true,
  //   //   );
  //   //   await invoke(service, 'removeTask', {'name': 'duifene'});
  //   //   return false;
  //   // }
  //
  //   // final currentCourseName = _getCurrentCourseName();
  //   // final matchedCourses = _courses.where(
  //   //   (course) =>
  //   //       course.courseName.pureString.withoutPunctuation
  //   //           .similarityTo(currentCourseName) >=
  //   //       threshold,
  //   // );
  //
  //   // if (matchedCourses.isEmpty) {
  //   //   _notificationManager.showNotification(
  //   //       enabled: enableNotification, content: '已签到$_signCount次，等待上课...');
  //   //   await _changeStatus(service, DuiFenESignInStatus.waiting);
  //   //   return false;
  //   // }
  //
  //   // final matched = matchedCourses.first;
  //   // _currentCourse = matched;
  //
  //   // _notificationManager.showNotification(
  //   //   enabled: enableNotification,
  //   //   content: '已签到$_signCount次，正在监听${_courses.length}个课程的签到',
  //   // );
  //   // _status = DuiFenESignInStatus.watching;
  //   return true;
  // }

  Future<DuiFenESignBase?> _checkSingleCourseSignIn(
    ServiceInstance service,
    bool enableNotification,
    DuiFenECourse course,
  ) async {
    final result = await duifeneService!.checkSignIn(course);
    if (result.status == Status.notAuthorized) {
      await invoke(service, 'removeTask', {'name': 'duifene'});
      final box = await _box;
      await box.put('enableAutomaticSignIn', false);
      await box.put('isLogin', false);
      _notificationManager.showNotification(
        enabled: enableNotification,
        content: '登录状态失效，请重新登录',
        enableVibration: true,
        standAlone: true,
      );
      _status = DuiFenESignInStatus.notAuthorized;
    }

    if (result.status != Status.ok) {
      return null;
    }

    final container = result.value!;
    if (_signedId.contains(container.id)) return null;
    _currentSignInContainer = container;
    return container;
  }

  Future<void> _checkSignIn(
      ServiceInstance service, bool enableNotification) async {
    _status = DuiFenESignInStatus.waiting;
    // final isInCourse = await _checkCurrentCourse(service, enableNotification);
    // if (!isInCourse) {
    //   _status = DuiFenESignInStatus.waiting;
    //   return;
    // }

    if (_courses.isNotEmpty) {
      _notificationManager.showNotification(
        enabled: enableNotification,
        content: '已签到$_signCount次，正在监听${_courses.first.courseName}的签到',
      );
    }

    if (duifeneService == null) {
      _status = DuiFenESignInStatus.watching;
      return;
    }

    var flag = false;
    for (final course in _courses) {
      final container =
          await _checkSingleCourseSignIn(service, enableNotification, course);
      if (container == null) {
        await Future.delayed(Duration(milliseconds: 500));
        continue;
      }

      _currentCourse = course;
      // await invoke(service, 'duifeneSigned');
      String prefix = switch (container) {
        DuiFenESignCodeSign _ => '签到码：${container.signCode}',
        DuiFenELocationSign _ => '定位签到',
        DuiFenESignBase _ => '未知签到',
      };
      _notificationManager.showNotification(
        enabled: enableNotification,
        content: '$prefix 剩余时间：${container.secondsRemaining} 等待签到...',
        enableVibration: true,
      );
      _status = DuiFenESignInStatus.signing;
      flag = true;
    }

    if (!flag) {
      _status = DuiFenESignInStatus.watching;
    }
  }

  Future<void> _signIn(ServiceInstance service, bool enableNotification) async {
    if (duifeneService == null ||
        _currentCourse == null ||
        _currentSignInContainer == null) {
      return;
    }

    StatusContainer<String>? result;
    if (_currentSignInContainer is DuiFenESignCodeSign) {
      final r = _currentSignInContainer as DuiFenESignCodeSign?;
      result = await duifeneService!.signInWithSignCode(r!.signCode);
    } else if (_currentSignInContainer is DuiFenELocationSign) {
      final r = _currentSignInContainer as DuiFenELocationSign?;
      result =
          await duifeneService!.signInWithLocation(r!.longitude, r.latitude);
    }

    if (result?.status != Status.ok) return;

    _signCount++;
    _signedId.add(_currentSignInContainer!.id);

    String suffix = switch (_currentSignInContainer!) {
      DuiFenESignCodeSign _ =>
        '签到码：${(_currentSignInContainer as DuiFenESignCodeSign?)?.signCode}',
      DuiFenELocationSign _ => '定位签到',
      DuiFenESignBase _ => '未知签到',
    };
    _notificationManager.showNotification(
      enabled: true,
      content: '${_currentCourse!.courseName}签到成功！$suffix',
      enableVibration: true,
      standAlone: true,
    );

    _currentSignInContainer = null;
    if (_courses.isNotEmpty) {
      _notificationManager.showNotification(
        enabled: enableNotification,
        content: '已签到$_signCount次，正在监听${_courses.first.courseName}的签到',
      );
    }
    _status = DuiFenESignInStatus.watching;
  }

  @override
  Future<void> run(ServiceInstance service, bool enableNotification) async {
    if (duifeneService == null) {
      duifeneService ??= DuiFenEApiService();
      await duifeneService!.init();
    }

    // service.on('duifeneCurrentCourse').listen((event) {
    //   String term = event!['term'] as String;
    //   List<Map<String, dynamic>> entries =
    //       (event['entries'] as List<dynamic>).cast();
    //   _term = term;
    //   _entries = entries.map((entry) => CourseEntry.fromJson(entry)).toList();
    // });

    service.on('duifeneCourses').listen((event) {
      List<Map<String, dynamic>> s = (event!['data'] as List<dynamic>).cast();
      _courses = s.map((e) => DuiFenECourse.fromJson(e)).toList();
    });

    service.on('duifeneChangeSignInNotificationStatus').listen((event) {
      bool isEnabled = event!['isEnabled'] as bool;
      _isSignInNotificationEnabled = isEnabled;
    });

    final notificationEnabled =
        enableNotification && _isSignInNotificationEnabled;
    switch (_status) {
      case DuiFenESignInStatus.initializing:
        if (_courses.isNotEmpty) {
          _notificationManager.showNotification(
              enabled: notificationEnabled,
              content: '已签到$_signCount次，正在监听${_courses.first.courseName}的签到');
        }
        _status = DuiFenESignInStatus.watching;
        return;
      case DuiFenESignInStatus.waiting:
        // await _checkCurrentCourse(service, notificationEnabled);
        return;
      case DuiFenESignInStatus.watching:
        await _checkSignIn(service, notificationEnabled);
        return;
      case DuiFenESignInStatus.signing:
        await _signIn(service, notificationEnabled);
        return;
      case DuiFenESignInStatus.stopped:
        if (_courses.isNotEmpty) {
          _notificationManager.showNotification(
            enabled: notificationEnabled,
            content: '已签到$_signCount次，正在监听${_courses.first.courseName}的签到',
          );
        }
        _status = DuiFenESignInStatus.waiting;
      case DuiFenESignInStatus.notAuthorized:
        return;
    }
  }

  @override
  Future<void> stop(ServiceInstance service, bool enableNotification) async {
    _notificationManager.showNotification(
      enabled: enableNotification,
      content: '已签到$_signCount次，已停止',
    );
    _status = DuiFenESignInStatus.stopped;
  }
}
