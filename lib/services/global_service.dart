/*
 * Copyright (c) 2025 BEND
 *
 * This file is a secondary development based on the original project.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as iaw;
import 'package:swustmeow/api/hitokoto_api.dart';
import 'package:swustmeow/data/activities_store.dart';
import 'package:swustmeow/entity/activity.dart';
import 'package:swustmeow/entity/duifene/duifene_course.dart';
import 'package:swustmeow/entity/run_mode.dart';
import 'package:swustmeow/services/account/account_service.dart';
import 'package:swustmeow/services/account/apartment_service.dart';
import 'package:swustmeow/services/account/chaoxing_service.dart';
import 'package:swustmeow/services/account/duifene_service.dart';
import 'package:swustmeow/services/account/ykt_service.dart';
import 'package:swustmeow/services/color_service.dart';
import 'package:swustmeow/services/notification_service.dart';
import 'package:swustmeow/services/background_service.dart';
import 'package:swustmeow/services/tasks/background_task.dart';
import 'package:swustmeow/services/tasks/duifene_sign_in_task.dart';
import 'package:swustmeow/services/uri_subscription_service.dart';
import 'package:swustmeow/services/value_service.dart';
import 'package:swustmeow/services/webview_cookie_service.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/widgets/course_table/course_table_widget_manager.dart';
import 'package:swustmeow/widgets/single_course/single_course_widget_manager.dart';
import 'package:swustmeow/widgets/today_courses/today_courses_widget_manager.dart';

import '../data/values.dart';
import '../entity/soa/course/courses_container.dart';
import '../entity/soa/course/term_date.dart';
import '../utils/courses.dart';
import 'account/soa_service.dart';
import 'boxes/common_box.dart';
import 'boxes/course_box.dart';
import 'boxes/duifene_box.dart';

class GlobalService {
  static MediaQueryData? mediaQueryData;
  static Size? size;
  static final Dio _fastDio = Dio(BaseOptions(
    sendTimeout: Duration(seconds: 2),
    receiveTimeout: Duration(seconds: 2),
    connectTimeout: Duration(seconds: 2),
  ));

  static UriSubscriptionService? uriSubscriptionService;
  static StatusContainer<dynamic>? reviewAuthResult;

  static NotificationService? notificationService;
  static List<AccountService> services = [];
  static SOAService? soaService;
  static DuiFenEService? duifeneService;
  static ApartmentService? apartmentService;
  static YKTService? yktService;
  static ChaoXingService? chaoXingService;

  static ValueNotifier<Map<String, TermDate>> termDates = ValueNotifier({});
  static ValueNotifier<List<Activity>> extraActivities = ValueNotifier([]);
  static ValueNotifier<List<DuiFenECourse>> duifeneCourses = ValueNotifier([]);
  static ValueNotifier<List<DuiFenECourse>> duifeneSelectedCourses =
      ValueNotifier([]);

  static BackgroundService? backgroundService;
  static Map<String, BackgroundTask> backgroundTaskMap = {
    'duifene': DuiFenESignInTask()
  };

  static SingleCourseWidgetManager? singleCourseWidgetManager;
  static TodayCoursesWidgetManager? todayCoursesWidgetManager;
  static CourseTableWidgetManager? courseTableWidgetManager;

  static iaw.CookieManager? webViewCookieManager;
  static WebViewCookieService? webViewCookieService;

  static Future<void> load({bool force = false}) async {
    final stopwatch = Stopwatch()..start();

    try {
      webViewCookieManager = iaw.CookieManager();
      webViewCookieService = WebViewCookieService();
      webViewCookieService!.init();
      ColorService.reload();
      final futures = <Future>[
        loadCommon(),
        _initializeServices(),
      ];
      
      await Future.wait(futures);
      loadCachedCoursesContainers();
      _loadNonCriticalFeaturesAsync(force: force);
      
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      rethrow;
    } finally {
      stopwatch.stop();
    }
  }

  static Future<void> _initializeServices() async {
    final futures = <Future>[
      () async {
        notificationService ??= NotificationService();
        await notificationService!.init();
      }(),
      () async {
        soaService ??= SOAService();
        await soaService!.init();
      }(),
      () async {
        duifeneService ??= DuiFenEService();
        await duifeneService!.init();
      }(),
      () async {
        apartmentService ??= ApartmentService();
        apartmentService!.init();
      }(),
      () async {
        yktService ??= YKTService();
        yktService!.init();
      }(),
      () async {
        chaoXingService ??= ChaoXingService();
        chaoXingService!.init();
      }(),
    ];
    
    await Future.wait(futures);
    services = [
      soaService!,
      apartmentService!,
      yktService!,
      duifeneService!,
      chaoXingService!
    ];
    
  }

  static void _loadNonCriticalFeaturesAsync({bool force = false}) {
    () async {
      try {
        await loadExtraActivities(force: force);
        loadDuiFenECourses();
        loadBackgroundService();
        
        if (Platform.isAndroid) {
          singleCourseWidgetManager ??= SingleCourseWidgetManager();
          todayCoursesWidgetManager ??= TodayCoursesWidgetManager();
          courseTableWidgetManager ??= CourseTableWidgetManager();
        }
        
      } catch (e, st) {
        debugPrintStack(stackTrace: st);
      }
    }();
  }

  static Future<void> dispose() async {
    await uriSubscriptionService?.dispose();
    await notificationService?.dispose();
    backgroundService?.stop();
  }

  static Future<void> loadCommon() async {
    final futures = <Future>[
      _loadTermDatesIfNeeded(),
      _loadHitokotoIfNeeded(),
    ];
    
    await Future.wait(futures);
  }

  static Future<void> _loadTermDatesIfNeeded() async {
    final cached = CourseBox.get('termDates'); 
    
    if (cached == null) {
      await loadTermDates();
    } else {
      if (cached is Map) {
        termDates.value = cached.cast<String, TermDate>();
        
      }
      loadTermDates(); 
    }
  }

  static Future<void> _loadHitokotoIfNeeded() async {
    if (CommonBox.get('hitokoto') == null) {
      await loadHitokoto();
    } else {
      loadHitokoto(); 
    }
  }

  static Future<void> loadBackgroundService() async {
    try {
      final runMode =
          (CommonBox.get('bgServiceRunMode') as RunMode?) ?? RunMode.foreground;
      final enableNotification =
          (CommonBox.get('bgServiceNotification') as bool?) ?? true;
      backgroundService = BackgroundService(
          initialRunMode: runMode, enableNotification: enableNotification);
      await backgroundService!.init();
      await backgroundService!.start();
      await loadBackgroundTasks();
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> loadBackgroundTasks() async {
    try {
      final service = FlutterBackgroundService();
      final tasks = <String>[];

      for (final name in backgroundTaskMap.keys) {
        final task = backgroundTaskMap[name];
        if (await task?.shouldAutoStart == true) {
          tasks.add(name);
        }
      }

      for (final taskName in tasks) {
        service.invoke('addTask', {'name': taskName});
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
    }
  }

  static void loadCachedCoursesContainers() {
    ValueService.customCourses =
        (CourseBox.get('customCourses') as Map<dynamic, dynamic>? ?? {}).cast();

    final cached = _getCachedCoursesContainers();
    if (cached != null && cached.where((c) => c.id == null).isEmpty) {
      final cachedWithCustomCourses =
          cached.map((cc) => cc.withCustomCourses).toList();

      final current = getCurrentCoursesContainer(
          ValueService.activities, cachedWithCustomCourses);
      final (today, currentCourse, nextCourse) =
          getCourse(current.term, current.entries);
      ValueService.coursesContainers = cachedWithCustomCourses;
      ValueService.todayCourses = today;
      ValueService.currentCoursesContainer.value = current;
      ValueService.currentCourse = currentCourse;
      ValueService.nextCourse = nextCourse;
      ValueService.cacheSuccess = true;
      ValueService.isCourseLoading.value = false;
    } else {
      ValueService.cacheSuccess = false;
      ValueService.isCourseLoading.value = true;
    }
  }

  static List<CoursesContainer>? _getCachedCoursesContainers() {
    List<dynamic>? result = CourseBox.get('courseTables');
    if (result == null) return null;
    return result.isEmpty ? [] : result.cast<CoursesContainer>();
  }

  static Future<void> loadExtraActivities({bool force = false}) async {
    try {
      final result = await getExtraActivities(force: force);
      if (result.status == Status.ok) {
        extraActivities.value = result.value!;
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> loadDuiFenECourses() async {
    try {
      final service = FlutterBackgroundService();

      final result = await duifeneService?.getCourseList(false);
      if (result != null && result.status == Status.ok) {
        if (result.value is List) {
          List<DuiFenECourse> value = (result.value! as List<dynamic>).cast<DuiFenECourse>();
          duifeneCourses.value = value;
        }
      }

      List<DuiFenECourse> selected =
          ((DuiFenEBox.get('coursesSelected') as List<dynamic>?) ?? []).cast<DuiFenECourse>();
      duifeneSelectedCourses.value = selected;
      service.invoke(
          'duifeneCourses', {'data': selected.map((s) => s.toJson()).toList()});
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> loadHitokoto() async {
    try {
      final hitokoto = await getHitokoto();
      final string = hitokoto.value?.hitokoto;
      if (string != null) {
        await CommonBox.put('hitokoto', string);
        await CommonBox.put('hitokotoFrom', hitokoto.value?.from);
        await CommonBox.put('hitokotoFromWho', hitokoto.value?.fromWho);
      }
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> loadTermDates() async {
    Map<String, TermDate> result = {};

    final cached = CourseBox.get('termDates') as Map<dynamic, dynamic>?;
    if (cached != null) {
      termDates.value = cached.cast();
      
    }

    try {
      final response = await _fastDio.get(Values.termDatesUrl);
      final data = response.data as Map<String, dynamic>;
      
      for (final term in data.keys) {
        final start = data[term]['start'] as String;
        final end = data[term]['end'] as String;
        final weeks = data[term]['weeks'] as int;
        result[term] = TermDate(
          start: DateTime.parse(start),
          end: DateTime.parse(end),
          weeks: weeks,
        );
        
      }
      await CourseBox.put('termDates', result);
      termDates.value = result;
      
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
    }
  }

  static Future<void> refreshHomeCourseWidgets() async {
    if (!Platform.isAndroid) return;

    try {
      singleCourseWidgetManager?.updateState();
      await singleCourseWidgetManager?.updateWidget();
      todayCoursesWidgetManager?.updateState();
      await todayCoursesWidgetManager?.updateWidget();
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
    }
  }
}
