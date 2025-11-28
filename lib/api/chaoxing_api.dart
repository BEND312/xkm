import 'dart:convert';
import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swustmeow/entity/chaoxing/chaoxing_course.dart';
import 'package:swustmeow/entity/chaoxing/chaoxing_exam.dart';
import 'package:swustmeow/entity/chaoxing/chaoxing_homework.dart';

import '../utils/status.dart';

class ChaoXingApiService {
  final _dio = Dio();
  static const _host = 'https://chaoxing.com';
  late PersistCookieJar _cookieJar;

  Future<void> init() async {
    await _initializeCookieJar();
    _dio.options.headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36 Edg/134.0.0.0',
      'Referer':
          'https://mooc1-2.chaoxing.com/visit/interaction?s=a5913ee5215774a303a05e9c9358f603',
    };
    _dio.options.validateStatus = (status) => true; // 忽略证书验证
    _dio.options.sendTimeout = const Duration(seconds: 10);
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        () => HttpClient()..badCertificateCallback = (cert, host, port) => true;
  }

  Future<void> _initializeCookieJar() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiesPath = '${appDocDir.path}/cookies';
    _cookieJar = PersistCookieJar(storage: FileStorage(cookiesPath));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<List<Cookie>> get cookies async =>
      await _cookieJar.loadForRequest(Uri.parse(_host));

  Future<String> get cookieString async =>
      (await cookies).map((c) => '${c.name}=${c.value}').join('; ');

  Future<void> deleteCookies() async {
    await _cookieJar.deleteAll();
  }

  /// 登录到超星学习通
  ///
  /// 返回一个是否登录成功的状态容器。
  Future<StatusContainer<dynamic>> login(
      String username, String password) async {
    try {
      await _cookieJar.deleteAll();
      final response = await _dio.post(
          'http://passport2-api.chaoxing.com/v11/loginregister?code=$password&cx_xxt_passport=json&uname=$username&loginType=1&roleSelect=true');
      final data =
          json.decode(response.data as String) as Map<dynamic, dynamic>;
      final status = data['status'] as bool? ?? false;
      final message = data['mes'] as String?;

      return StatusContainer(
          status ? Status.ok : Status.fail, message ?? '未知错误');
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取所有课程的列表
  ///
  /// 如果获取成功，返回一个 [ChaoXingCourse] 的列表的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<dynamic>> getCourseList() async {
    try {
      final response = await _dio
          .get('http://mooc1-api.chaoxing.com/mycourse/backclazzdata');
      final data =
          json.decode(response.data as String) as Map<dynamic, dynamic>;
      final message = data['msg'] as String?;
      final channelList = data['channelList'] as List<dynamic>?;

      if (channelList == null) {
        return StatusContainer(Status.fail, message ?? '无法获取课程列表');
      }

      final result = <ChaoXingCourse>[];
      for (final classJson in channelList) {
        final cataName = classJson['cataName'] as String?;
        final cpi = classJson['cpi'] as int?;
        final classId = classJson['key'] as int?;
        if (cataName != '课程' || cpi == null || classId == null) continue;

        final content = classJson['content'] as Map<dynamic, dynamic>?;
        if (content == null) continue;
        final course = content['course'] as Map<dynamic, dynamic>?;
        if (course == null) continue;
        final courses = course['data'] as List<dynamic>?;
        if (courses == null) continue;

        for (final courseJson in courses) {
          final courseName = courseJson['name'] as String?;
          final teacherName = courseJson['teacherfactor'] as String?;
          final courseId = courseJson['id'] as int?;

          if (courseName == null || teacherName == null || courseId == null) {
            continue;
          }

          result.add(ChaoXingCourse(
            courseName: courseName,
            teacherName: teacherName.replaceAll(' ', ''),
            classId: classId,
            courseId: courseId,
            cpi: cpi,
          ));
        }
      }

      return StatusContainer(Status.ok, result);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取 enc
  Future<StatusContainer<String>> _getWorkEnc(ChaoXingCourse course) async {
    try {
      getOptions() async => Options(
            headers: {
              'Accept-Language': 'zh-Hans-CN;q=1, zh-Hant-CN;q=0.9',
              'cookie': await cookieString,
              'Accept-Encoding': 'identity',
              'User-Agent':
                  'Mozilla/5.0 (iPhone; CPU iPhone OS 14_2_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 com.ssreader.ChaoXingStudy/ChaoXingStudy_3_4.8_ios_phone_202012052220_56 (@Kalimdor)_12787186548451577248',
            },
            preserveHeaderCase: true,
            followRedirects: false,
          );

      final resp1 = await _dio.get(
        'http://mooc1-2.chaoxing.com/mooc-ans/visit/stucoursemiddle?courseid=${course.courseId}&clazzid=${course.classId}&vc=1&cpi=${course.cpi}&ismooc2=1&v=2',
        options: await getOptions(),
      );
      final loc1 = resp1.headers['Location']?.firstOrNull;
      if (loc1 == null) {
        return StatusContainer(Status.fail, '无法获取 enc（1）');
      }

      final resp2 = await _dio.get(loc1, options: await getOptions());
      final html = resp2.data as String?;
      if (html == null) {
        return StatusContainer(Status.fail, '请求 enc 失败');
      }

      final soup = BeautifulSoup(html);
      final workEnc = soup.find('*', id: 'workEnc')?.getAttrValue('value');
      if (workEnc == null) {
        return StatusContainer(Status.fail, '获取 enc 失败');
      }

      return StatusContainer(Status.ok, workEnc);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取所有的作业列表
  ///
  /// 如果获取成功，返回一个 [ChaoXingHomework] 的列表的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<dynamic>> getHomeworks(ChaoXingCourse course) async {
    try {
      final encResult = await _getWorkEnc(course);
      if (encResult.status != Status.ok) {
        return StatusContainer(Status.fail, '获取作业列表失败，无法获取 enc');
      }

      final response = await _dio.get(
          'https://mooc1.chaoxing.com/mooc2/work/list?courseId=${course.courseId}&classId=${course.classId}&cpi=${course.cpi}&ut=s&enc=${encResult.value}');
      final html = response.data as String?;
      if (html == null) {
        return StatusContainer(Status.fail, '请求作业列表失败');
      }

      final soup = BeautifulSoup(html);
      final bottomList = soup.findAll('*', class_: 'bottomList').firstOrNull;
      final ul = bottomList?.children.firstOrNull;
      final lis = ul?.children;
      if (lis == null) {
        return StatusContainer(Status.ok, []);
      }

      final result = <ChaoXingHomework>[];
      for (final li in lis) {
        final rightContent = li.find('*', class_: 'right-content');
        if (rightContent == null) continue;

        final title = rightContent.children.firstOrNull?.text;
        final labels = rightContent
            .findAll('*', class_: 'label')
            .map((el) => el.text.trim())
            .toList();
        final status =
            (rightContent.find('*', class_: 'status')?.text ?? '未交').trim();
        if (title == null) continue;

        result.add(ChaoXingHomework(
          title: title,
          labels: labels,
          status: status,
        ));
      }

      return StatusContainer(Status.ok, result);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取所有的考试列表
  ///
  /// 如果获取成功，返回一个 [ChaoXingExam] 的列表的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<dynamic>> getExams(ChaoXingCourse course) async {
    try {
      final encResult = await _getWorkEnc(course);
      if (encResult.status != Status.ok) {
        return StatusContainer(Status.fail, '获取考试列表失败，无法获取 enc');
      }

      final response = await _dio.get(
          'https://mooc1.chaoxing.com/exam-ans/mooc2/exam/exam-list?courseid=${course.courseId}&clazzid=${course.classId}&cpi=${course.cpi}&ut=s&enc=${encResult.value}');
      final html = response.data as String?;
      if (html == null) {
        return StatusContainer(Status.fail, '请求考试列表失败');
      }

      final soup = BeautifulSoup(html);
      final bottomList = soup.findAll('*', class_: 'bottomList').firstOrNull;
      final ul = bottomList?.children.firstOrNull;
      final lis = ul?.children;
      if (lis == null) {
        return StatusContainer(Status.ok, []);
      }

      final result = <ChaoXingExam>[];
      for (final li in lis) {
        final rightContent = li.find('*', class_: 'right-content');
        if (rightContent == null) continue;

        final title = rightContent.children.firstOrNull?.text;
        final status =
            (rightContent.find('*', class_: 'status')?.text ?? '未交').trim();
        if (title == null) continue;

        result.add(ChaoXingExam(
          title: title,
          status: status,
        ));
      }

      return StatusContainer(Status.ok, result);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }
}
