/*
 * Copyright (c) 2025 BEND
 *
 * This file is a secondary development based on the original project.
 * Original work is licensed under Apache License 2.0 (see LICENSE-APACHE-2.0).
 * Modifications and additions are licensed under GPL-3.0 (see LICENSE-GPL-3.0).
 *
 * For more details, refer to the NOTICE file in the project root.
 */

import 'dart:convert';
import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:gbk_codec/gbk_codec.dart';
import 'package:swustmeow/data/values.dart';
import 'package:swustmeow/entity/soa/exam/exam_schedule.dart';
import 'package:swustmeow/entity/soa/exam/exam_type.dart';
import 'package:swustmeow/entity/soa/leave/daily_leave_options.dart';
import 'package:swustmeow/entity/soa/course/optional_course.dart';
import 'package:swustmeow/entity/soa/course/optional_task_type.dart';
import 'package:swustmeow/entity/soa/course/optional_course_type.dart';
import 'package:swustmeow/entity/soa/score/course_score.dart';
import 'package:swustmeow/entity/soa/score/points_data.dart';
import 'package:swustmeow/entity/soa/score/score_type.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/list.dart';
import 'package:swustmeow/utils/math.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:path_provider/path_provider.dart';

import '../dio_cookie_interceptor.dart';
import '../entity/soa/course/course_entry.dart';
import '../entity/soa/course/course_type.dart';
import '../entity/soa/course/courses_container.dart';
import '../entity/soa/leave/daily_leave_display.dart';
import '../entity/soa/evaluation_paper.dart';
import '../utils/http.dart';

class SOAApiService {
  final dio = Dio();
  static const ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0';
  static const defaultHeaders = {
    'User-Agent': ua,
    'Accept-Language':
        'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
    'Accept': '*/*',
    'Accept-Encoding': 'gzip, deflate',
  };
  late PersistCookieJar _cookieJar;
  ResponseDecoder gbkDecoder =
      (r, _, __) => gbk_bytes.decode(r); // 处理 GB2312/GBK 变为 UTF-8

  Future<void> init() async {
    await _initializeCookieJar();
    dio.options.headers = defaultHeaders;
    dio.options.validateStatus = (status) => true; // 忽略证书验证
    dio.options.sendTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.connectTimeout = const Duration(seconds: 10);

    // 修复 `CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate` 的问题
    // https://stackoverflow.com/a/60890158/15809316
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        () => HttpClient()..badCertificateCallback = (cert, host, port) => true;

    dio.interceptors.add(DioCookieInterceptor(key: 'soa'));
  }

  Future<void> _initializeCookieJar() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiesPath = '${appDocDir.path}/cookies';
    _cookieJar = PersistCookieJar(storage: FileStorage(cookiesPath));
    dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<List<Cookie>> getCookies(Uri uri) async {
    return await _cookieJar.loadForRequest(uri);
  }

  Future<String> getCookiesString(Uri uri) async {
    final list = await getCookies(uri);
    return list.map((c) => '${c.name}=${c.value}').join('; ');
  }

  Future<void> deleteCookies() async {
    await _cookieJar.deleteAll();
  }

  /// RSA 加密函数
  /// [plaintext] 明文字符串
  /// [modulus] 模数（16进制字符串）
  /// [exponent] 指数（16进制字符串）
  static String _rsaEncrypt(String plaintext, String modulus, String exponent) {
    // 将模数和指数从16进制转换成BigInt
    BigInt m = BigInt.parse(modulus, radix: 16);
    BigInt e = BigInt.parse(exponent, radix: 16);

    // 将明文字符串以 UTF-8 编码成字节数组
    List<int> textBytes = utf8.encode(plaintext);

    // 将字节数组转换为大整数（大端字节序）
    BigInt inputNr = _bytesToBigInt(textBytes);

    // 进行模幂运算：RSA加密核心
    BigInt cryptNr = inputNr.modPow(e, m);

    // 计算模数对应的字节长度：ceil(bitLength / 8)
    int byteLength = ((m.toRadixString(2).length + 7) ~/ 8);

    // 将加密结果转换回固定长度的字节数组（大端字节序）
    List<int> cryptData = _bigIntToBytes(cryptNr, byteLength);

    // 将字节数组转换为16进制字符串返回
    return _bytesToHex(cryptData);
  }

  /// 将字节数组（大端）转换为 BigInt
  static BigInt _bytesToBigInt(List<int> bytes) {
    BigInt result = BigInt.zero;
    for (int byte in bytes) {
      result = (result << 8) | BigInt.from(byte);
    }
    return result;
  }

  /// 将 BigInt 转换为固定长度的字节数组（大端）
  static List<int> _bigIntToBytes(BigInt number, int length) {
    List<int> result = List.filled(length, 0);
    BigInt temp = number;
    for (int i = length - 1; i >= 0; i--) {
      result[i] = (temp & BigInt.from(0xff)).toInt();
      temp = temp >> 8;
    }
    return result;
  }

  /// 将字节数组转换为16进制字符串
  static String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 登录到一站式
  ///
  /// 返回一个 (最后一个请求响应体, 带有 TGC 或错误字符串) 的状态容器。
  static Future<StatusContainer<(Response?, String?)>> loginToSOA({
    required Dio dio,
    required String username,
    required String password,
    String? url,
    int captchaRetry = 3,
    String? manualCaptcha,
  }) async {
    try {
      final loginUrl = 'http://cas.swust.edu.cn/authserver/login';
      final loginResp = await dio.get(
        url ?? loginUrl,
        options: Options(
          headers: {'Host': 'cas.swust.edu.cn'},
        ),
      );
      final execution = RegExp(r'name="execution"\s+value="(.*?)"')
          .firstMatch(loginResp.data as String)
          ?.group(1);
      if (execution == null) {
        return StatusContainer(Status.fail, (loginResp, '登录失败'));
      }

      final getKeyResp = await dio.get(
        'http://cas.swust.edu.cn/authserver/getKey',
        options: Options(
          headers: {'Host': 'cas.swust.edu.cn'},
        ),
      );
      final publicKey = getKeyResp.data as Map<String, dynamic>;
      final encryptedPassword =
          _rsaEncrypt(password, publicKey['modulus'], publicKey['exponent']);

      Future<String> getCaptchaBase64() async {
        final captchaResp = await dio.get(
          'http://cas.swust.edu.cn/authserver/captcha',
          options: Options(
            headers: {'Host': 'cas.swust.edu.cn'},
            responseType: ResponseType.bytes,
          ),
        );
        return base64Encode(captchaResp.data as List<int>);
      }

      var captchaResult = manualCaptcha;
      if (manualCaptcha == null) {
        // 无法自动识别验证码，需要手动输入
        final captcha = await getCaptchaBase64();
        return StatusContainer(Status.manualCaptchaRequired, (null, captcha));
      }

      final data = {
        'execution': execution,
        '_eventId': 'submit',
        'geolocation': '',
        'username': username,
        'lm': 'usernameLogin',
        'password': encryptedPassword,
        'captcha': captchaResult!.toUpperCase(),
      };

      final resp = await dio.post(
        loginUrl,
        data: data,
        options: Options(
          headers: {
            'Host': 'cas.swust.edu.cn',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );
      final code = resp.statusCode;

      if (code == 401) {
        final textError = RegExp(r'<p class="textError">\s*<b>(.*?)</b>\s*</p>')
            .firstMatch(resp.data as String)
            ?.group(1);
        if (textError != null && textError == '验证码无效') {
          captchaRetry--;
          if (captchaRetry <= 0) {
            final captcha = await getCaptchaBase64();
            return StatusContainer(Status.captchaFailed, (resp, captcha));
          }
          return await loginToSOA(
            dio: dio,
            username: username,
            password: password,
            captchaRetry: captchaRetry,
            manualCaptcha: manualCaptcha,
          );
        }
        return StatusContainer(Status.fail, (resp, '未知错误：$textError'));
      } else if (code == 302) {
        final setCookie = resp.headers.map['Set-Cookie']?.firstOrNull;
        final tgc = getCookieValue(setCookie, 'TGC');
        if (tgc == null) {
          return StatusContainer(Status.fail, (resp, '系统异常，请重试（1）'));
        }
        return StatusContainer(Status.ok, (resp, tgc));
      } else {
        return StatusContainer(Status.fail, (resp, '系统异常，请重试（2）'));
      }
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      showErrorToast('登录异常，请加群反馈：$e', seconds: 5);
      return StatusContainer(Status.fail, (null, '登录异常'));
    }
  }

  Future<StatusContainer<dynamic>> getExperimentCourseEntries(
      String tgc, String term) async {
    try {
      var fixedTerm = term;
      final shouldFix = int.tryParse(fixedTerm.characters.last) == null;
      if (shouldFix) {
        final [s, e, i] = fixedTerm.split('-');
        fixedTerm = '$s-$e-${i == '上' ? '1' : '2'}';
      }

      final loginResp = await dio.get(
        'http://cas.swust.edu.cn/authserver/login?service=https://sjjx.dean.swust.edu.cn/swust/',
        options: Options(
          headers: {'Host': 'cas.swust.edu.cn', 'Cookie': 'TGC=$tgc'},
          followRedirects: false,
        ),
      );

      final location = loginResp.headers.value('Location');
      if (location == null) {
        return StatusContainer(Status.fail, '无法登录到实践教学系统');
      }

      await dio.get(location);

      var page = 1;
      List<CourseEntry> result = [];

      while (true) {
        final resp = await dio.get(
          'https://sjjx.dean.swust.edu.cn/teachn/teachnAction/index.action?page.pageNum=$page&currTeachCourseCode=%25&currWeek=%25&currYearterm=$fixedTerm',
          options: Options(
            headers: {
              'Referer': 'http://sjjx.dean.swust.edu.cn/aexp/stuLeft.jsp',
              'Host': 'sjjx.dean.swust.edu.cn',
            },
          ),
        );
        final soup = BeautifulSoup(resp.data as String);
        final table = soup.findAll('table', class_: 'tablelist').lastOrNull;
        final tbody = table?.find('tbody');
        final lectures = tbody?.findAll('tr').sublist(1);
        if (table == null || tbody == null || lectures == null) {
          return StatusContainer(Status.fail, '获取失败');
        }

        for (final lecture in lectures) {
          final info = lecture.findAll('td');
          if (info.length < 5) continue;

          final course = info[0].text;
          final project = info[1].text;
          final time = info[2].text.trim();
          final timeData = RegExp(r'(\d+)周星期(.)(\d+)-(\d+)节')
              .firstMatch(time)
              ?.groups([1, 2, 3, 4]);
          if (timeData == null) continue;
          final [week, day, start, end] = timeData;

          final dayIndex = ['一', '二', '三', '四', '五', '六', '日'].indexOf(day!);
          final place = info[3].text;
          final teachers = info[4].text.trim();
          final teacher = teachers.split(RegExp(r'[\s/,，]+'));

          final entry = CourseEntry(
            courseName: course,
            teacherName: teacher,
            startWeek: tryParseInt(week) ?? 0,
            endWeek: tryParseInt(week) ?? 0,
            place: place,
            weekday: dayIndex + 1,
            numberOfDay: ((tryParseInt(end) ?? 0) / 2).toInt(),
            displayName: project,
            startSection: tryParseInt(start),
            endSection: tryParseInt(end),
          );
          result.add(entry);
        }

        final pageText = soup
            .find('div', id: 'myPage')!
            .find('ul')!
            .find('li')!
            .find('p')!
            .text;
        final [pageNow, pageAll] = RegExp(r'第 (\d+) 页 / 共 (\d+) 页')
            .firstMatch(pageText)!
            .groups([1, 2])
            .map(tryParseInt)
            .toList();
        if (pageNow == null || pageAll == null) break;
        if (pageNow >= pageAll) break;
        page = pageNow + 1;
      }
      return StatusContainer(Status.ok, result);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.failWithToast, null, '获取实验课表失败');
    }
  }

  /// 登录到课表系统
  ///
  /// 返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<String>> loginToMatrix(String tgc) async {
    try {
      final matrixAuthUrl =
          'http://cas.swust.edu.cn/authserver/login?service=https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=studentPortal:DEFAULT_EVENT';

      final headers = {
        'Cookie': 'TGC=$tgc; aexpsid=ED40D42341EAE10005B94BD58053D107.node1',
        'Content-Type': 'application/json',
      };

      final authResp = await dio.get(matrixAuthUrl,
          options: Options(headers: headers, followRedirects: false));

      if (authResp.statusCode != 302) {
        return const StatusContainer(Status.notAuthorized);
      }

      final loc = authResp.headers['Location']?.firstOrNull;
      if (loc == null) return const StatusContainer(Status.notAuthorized);

      final loginResp = await dio.get(
        loc,
        options: Options(headers: headers),
      );
      final loginHtml = loginResp.data as String;
      final errorMatched =
          RegExp(r"<div class='_err'>(\d*?)</div>").firstMatch(loginHtml);
      if (errorMatched != null) {
        final msg = RegExp(r"<div class='_1'>(.*?)</div>")
                .firstMatch(loginHtml)
                ?.group(1) ??
            '';
        final desc = RegExp(r"<div class='_2'>(.*?)</div>")
                .firstMatch(loginHtml)
                ?.group(1) ??
            '';
        return StatusContainer(Status.fail, '教务系统：$msg $desc');
      }

      return StatusContainer(Status.ok);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '无法登录到课表系统，请尝试切换网络并重试');
    }
  }

  /// 获取普通课和选课课程表
  ///
  /// 若获取成功，返回一个 [CoursesContainer] 的列表的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getCourseTables(String tgc) async {
    try {
      final r = await loginToMatrix(tgc);
      if (r.status != Status.ok) return r;

      // 不知道为什么第一次调用此函数时 cookie 是空的
      // 所以先调用一次来获取带有 JSESSIONID 的 cookie
      // TODO 修复这里的问题
      await getExperimentCourseEntries(
        tgc,
        GlobalService.termDates.value.entries.lastOrNull?.key ??
            Values.fallbackTerm,
      );

      Future<CoursesContainer?> getCourseFrom(
          String url, CourseType type) async {
        final courseResp = await dio.get(
          url,
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );
        final courseHtml = courseResp.data as String;

        final termRegex = RegExp(r'<h3>(\d+-\d+-\d) 学期 个人课表</h3>');
        final term = termRegex.firstMatch(courseHtml)?.group(1);

        if (term == null) return null;

        final [startYear, endYear, t] =
            term.split('-').map((c) => int.parse(c)).toList();
        final trueTerm = '$startYear-$endYear-${t == 1 ? '上' : '下'}';

        List<CourseEntry> res = [];
        final soup = BeautifulSoup(courseHtml);
        final table = soup.find('table', class_: 'UICourseTable');
        final sections = table?.find('tbody')?.findAll('tr');
        if (table == null || sections == null) {
          return null;
        }

        for (int i = 0; i < sections.length; i++) {
          var days = sections[i].findAll('td').sublist(1);

          // 去掉第一列的节数
          if (days[0].text.startsWith('第')) {
            days = days.sublist(1);
          }

          for (int j = 0; j < days.length; j++) {
            final day = days[j];
            for (final lecture in day.findAll('div', class_: 'lecture')) {
              final courseName = lecture.find('span', class_: 'course')!.text;
              final teachers = lecture.find('span', class_: 'teacher')!.text;
              final teacherName = teachers.split(RegExp(r'[\s/,，]+'));
              final week = lecture.find('span', class_: 'week')!.text;
              final [startWeek, endWeek] = week
                  .split('(')[0]
                  .split('-')
                  .map((c) => int.parse(c))
                  .toList();
              final place = lecture.find('span', class_: 'place')!.text;
              res.add(
                CourseEntry(
                  courseName: courseName,
                  displayName: courseName,
                  teacherName: teacherName,
                  startWeek: startWeek,
                  endWeek: endWeek,
                  place: place,
                  weekday: j + 1,
                  numberOfDay: i + 1,
                  startSection: (2 * (i + 1)) - 1,
                  endSection: 2 * (i + 1), // 普通课程表是标准的
                ),
              );
            }
          }
        }

        final userId = GlobalService.soaService?.currentAccount?.account;
        return CoursesContainer(
          type: type,
          term: trueTerm,
          entries: res,
          id: sha1
              .convert(
                utf8.encode('$userId${type.name}$term'),
              )
              .toString(),
        );
      }

      final normalCourse = await getCourseFrom(
          'https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=studentPortal:courseTable',
          CourseType.normal);
      final optionalCourse = await getCourseFrom(
          'https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=chooseCourse:courseTable',
          CourseType.optional);

      final result = <CoursesContainer>[];

      bool isExpOK = false;
      if (normalCourse != null) {
        final exp = await getExperimentCourseEntries(tgc, normalCourse.term);
        if (exp.status == Status.ok && exp.value != null) {
          List<CourseEntry> r = (exp.value! as List<dynamic>).cast();
          normalCourse.entries.addAll(r);
          isExpOK = true;
        }
        result.add(normalCourse);
      }

      if (optionalCourse != null && optionalCourse.term != normalCourse?.term) {
        final exp = await getExperimentCourseEntries(tgc, optionalCourse.term);
        if (exp.status == Status.ok && exp.value != null) {
          List<CourseEntry> r = (exp.value! as List<dynamic>).cast();
          optionalCourse.entries.addAll(r);
        }
        result.add(optionalCourse);
      }

      return StatusContainer(isExpOK ? Status.ok : Status.partiallyOkWithToast,
          result, isExpOK ? null : '实验课表获取失败');
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.failWithToast, null, '课表获取失败，请切换网络并重试');
    }
  }

  /// 根据类别获取选课的课程列表
  ///
  /// 若获取成功，返回一个 [OptionalCourse] 的列表的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getOptionalCourses(
      String tgc, OptionalTaskType taskType) async {
    try {
      final r = await loginToMatrix(tgc);
      if (r.status != Status.ok) return r;

      final response = await dio.get(
        'https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=chooseCourse:${taskType.type}&CT=2',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final soup = BeautifulSoup(response.data as String);

      final coursesList = soup.findAll('div', class_: 'courseShow');
      final result = <OptionalCourse>[];
      for (final element in coursesList) {
        final title = element.find('div', class_: 'title')!;
        final cid = title.find('a', class_: 'trigger')!.getAttrValue('cid')!;
        final name = title.find('span', class_: 'name')!.text;
        final credit = title.find('span', class_: 'numeric')!.text;
        final type = title.find('span', class_: 'type')!.text;
        result.add(OptionalCourse(
            cid: cid,
            name: name,
            credit: double.tryParse(credit) ?? 0.0,
            taskType: taskType,
            courseType: switch (type) {
              '网络通识课' => OptionalCourseType.internetGeneralCourse,
              '素质选修课' => OptionalCourseType.qualityOptionalCourse,
              _ => OptionalCourseType.unknown
            }));
      }

      return StatusContainer(Status.ok, result);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取所有的考试
  ///
  /// 若获取成功，返回一个 [ExamSchedule] 的列表的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getExams(String tgc) async {
    try {
      final r = await loginToMatrix(tgc);
      if (r.status != Status.ok) return r;

      final response = await dio.get(
        'https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=studentPortal:examTable',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final soup = BeautifulSoup(response.data as String);

      List<ExamSchedule> result = [];
      final numbers = {'一': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6, '日': 7};

      List<ExamSchedule> get(String id, ExamType type) {
        final div = soup.find('div', id: id);
        final table = div?.find('table');
        if (div == null || table == null) return [];
        final trs = table.findAll('tr', class_: 'editRows');
        List<ExamSchedule> r = [];
        for (final tr in trs) {
          final tds = tr.findAll('td');
          final courseName = tds[1].text;
          final weekNum = int.parse(tds[2].find('span')!.text);
          final orderChars = tds[3].text.characters.toList();
          final weekday = numbers[orderChars[1]]!;
          final numberOfDay = numbers[orderChars[3]]!;
          final date =
              DateTime.parse(tds[4].find('span')!.text.replaceAll('/', '-'));
          final classroom = tds[6].text;
          final seatNo = int.parse(tds[7].text);
          final place = tds[8].text;
          r.add(ExamSchedule(
            type: type,
            courseName: courseName,
            weekNum: weekNum,
            numberOfDay: numberOfDay,
            weekday: weekday,
            date: date,
            place: place,
            classroom: classroom,
            seatNo: seatNo,
          ));
        }
        return r;
      }

      result.addAll(get('finalExamTable', ExamType.finalExam));
      result.addAll(get('midExamTable', ExamType.midExam));
      result.addAll(get('resitExamTable', ExamType.resitExam));
      return StatusContainer(Status.ok, result);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取所有的考试成绩
  ///
  /// 若获取成功，返回一个 [CourseScore] 的列表的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getScores(String tgc) async {
    try {
      final r = await loginToMatrix(tgc);
      if (r.status != Status.ok) return r;

      final response = await dio.get(
        'https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=studentProfile:courseMark',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final soup = BeautifulSoup(response.data as String);

      List<CourseScore> result = [];

      List<CourseScore> getPlan(String id) {
        final div = soup.find('div', id: id);
        final tables = div?.findAll('table', class_: 'UItable') ?? [];
        final List<CourseScore> result = [];

        for (final table in tables) {
          final trs = table.findAll('tr');
          if (trs.isEmpty) continue;

          // 解析学年
          final yearElement = trs.first.find('*', selector: 'span.number.bold');
          final academicYear = yearElement?.text.trim() ?? '';

          String currentTerm = '';
          bool inTermSection = false;

          for (final tr in trs.skip(1)) {
            // 跳过标题行
            // 检测学期行
            final termTd = tr.find('*', selector: 'td[width="11"][rowspan]');
            if (termTd != null) {
              currentTerm = termTd.text.trim() == '秋' ? '上' : '下';
              inTermSection = true;
              continue;
            }

            // 检测绩点统计行（结束当前学期）
            if (tr.find('*', selector: 'td[colspan="8"]') != null) {
              inTermSection = false;
              continue;
            }

            if (inTermSection) {
              final tds = tr.findAll('td');
              if (tds.length < 7) continue; // 确保是课程行

              try {
                final courseName = tds[0].text.trim();
                if (courseName == '课程') continue;
                final courseId = tds[1].find('span')?.text.trim() ?? '';
                final credit = tryParseDouble(tds[2].find('span')?.text) ?? 0.0;
                final courseType = tds[3].text.trim();
                final formalScore =
                    tds[4].find('span')?.text.trim() ?? tds[4].text.trim();
                final resitScore =
                    tds[5].find('span')?.text.trim() ?? tds[5].text.trim();
                final points = tryParseDouble(tds[6].find('span')?.text);

                result.add(CourseScore(
                  courseName: courseName,
                  courseId: courseId,
                  credit: credit,
                  courseType: courseType,
                  formalScore: formalScore,
                  resitScore: resitScore,
                  points: points,
                  scoreType: ScoreType.plan,
                  term: '$academicYear-$currentTerm',
                ));
              } catch (e, st) {
                debugPrintStack(stackTrace: st);
              }
            }
          }
        }

        return result;
      }

      List<CourseScore> getOther(String id, ScoreType type) {
        assert(type != ScoreType.plan);
        final div = soup.find('div', id: id);
        final table = div?.find('table');
        if (div == null || table == null) return [];

        final trs = table.findAll('tr', class_: 'cellBorder');
        List<CourseScore> r = [];
        for (final tr in trs) {
          final tds = tr.findAll('td');
          final termList = tds[0].find('span')!.text.split('-');
          final term =
              '${termList[0]}-${termList[1]}-${termList[2] == '1' ? '上' : '下'}';
          final courseName = tds[1].text;
          final courseId = tds[2].find('span')!.text;
          final credit = double.parse(tds[3].find('span')!.text);
          final formalScore = tds[4].find('span')?.text ?? tds[4].text;
          final resitScore = tds[5].find('span')?.text ?? tds[5].text;
          final points =
              double.tryParse(tds[6].find('span')?.text ?? tds[6].text);
          r.add(
            CourseScore(
              courseName: courseName,
              courseId: courseId,
              credit: credit,
              courseType: null,
              formalScore: formalScore,
              resitScore: resitScore,
              points: points,
              scoreType: type,
              term: term,
            ),
          );
        }
        return r;
      }

      result.addAll(getPlan('Plan'));
      result.addAll(getOther('Common', ScoreType.common));
      result.addAll(getOther('Physical', ScoreType.physical));
      return StatusContainer(Status.ok, result);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取学分、绩点数据
  ///
  /// 如果获取成功，返回一个带有 [PointsData] 的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<dynamic>> getPointsData(String tgc) async {
    try {
      final r = await loginToMatrix(tgc);
      if (r.status != Status.ok) return r;

      final response = await dio.get(
        'https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=studentProfile:courseMark',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      final soup = BeautifulSoup(response.data as String);

      final summary = soup.find('div', id: 'Summary');
      final circles = summary?.findAll('div', class_: 'UICircle');
      if (summary == null || circles == null) {
        return StatusContainer(Status.fail, '未获取到学分绩点数据');
      }

      double? totalCredits;
      double? requiredCoursesCredits;
      double? averagePoints;
      double? requiredCoursesPoints;
      double? degreeCoursesPoints;

      final creditsCircleLis = circles.first.findAll('li');
      final pointsCircleLis = circles.last.findAll('li');

      totalCredits =
          tryParseDouble(creditsCircleLis.safeGet(0)?.find('em')?.text);
      requiredCoursesCredits =
          tryParseDouble(creditsCircleLis.safeGet(1)?.find('em')?.text);
      averagePoints =
          tryParseDouble(pointsCircleLis.safeGet(0)?.find('em')?.text);
      requiredCoursesPoints =
          tryParseDouble(pointsCircleLis.safeGet(1)?.find('em')?.text);
      degreeCoursesPoints =
          tryParseDouble(pointsCircleLis.safeGet(2)?.find('em')?.text);

      return StatusContainer(
        Status.ok,
        PointsData(
          totalCredits: totalCredits,
          requiredCoursesCredits: requiredCoursesCredits,
          averagePoints: averagePoints,
          requiredCoursesPoints: requiredCoursesPoints,
          degreeCoursesPoints: degreeCoursesPoints,
        ),
      );
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 登录到学工管理系统
  ///
  /// 返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<String>> loginToXSC(String tgc) async {
    try {
      final xscAuthUrl =
          'http://cas.swust.edu.cn/authserver/login?service=http://xsc.swust.edu.cn/JC/OneLogin.aspx';
      final headers = {
        'Cookie': 'TGC=$tgc; aexpsid=ED40D42341EAE10005B94BD58053D107.node1',
        'Content-Type': 'application/json',
      };

      final resp1 = await dio.get(xscAuthUrl,
          options: Options(headers: headers, followRedirects: false));
      if (resp1.statusCode != 302) {
        return const StatusContainer(Status.notAuthorized);
      }
      final loc1 = resp1.headers['Location']?.first;
      if (loc1 == null) return const StatusContainer(Status.notAuthorized);

      final resp2 = await dio.get(loc1,
          options: Options(followRedirects: false, headers: headers));
      if (resp2.statusCode != 302) {
        return const StatusContainer(Status.notAuthorized);
      }
      final loc2 = resp2.headers['Location']?.first;
      if (loc2 == null) return const StatusContainer(Status.notAuthorized);

      final resp3 = await dio.get(loc2, options: Options(headers: headers));
      final hrefRegex =
          RegExp(r"<script>window.location.href='(.*)';</script>");
      final loc3 = hrefRegex.firstMatch(resp3.data)?.group(1);
      if (loc3 == null) return StatusContainer(Status.ok);

      await dio.get(loc3, options: Options(headers: headers));
      return StatusContainer(Status.ok);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取已有日常请假的信息
  ///
  /// 若获取成功，返回一个 [DailyLeaveOptions] 的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getDailyLeaveInformation(
      String tgc, String id) async {
    try {
      final r = await loginToXSC(tgc);
      if (r.status != Status.ok) return r;

      final url =
          'http://xsc.swust.edu.cn/Sys/SystemForm/Leave/StuAllLeaveManage_Edit.aspx';
      final response = await dio.get(
        url,
        queryParameters: {'Status': 'Edit', 'Id': id},
        options: Options(
          responseDecoder: gbkDecoder,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      return StatusContainer(
          Status.ok, DailyLeaveOptions.fromHTML(response.data as String));
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取所有的日常请假
  ///
  /// 若获取成功，返回一个 [DailyLeaveDisplay] 的列表的状态容器；
  /// 否则，返回一个带有错误信息的字符串的状态容器。
  Future<StatusContainer<dynamic>> getDailyLeaves(String tgc) async {
    try {
      final r = await loginToXSC(tgc);
      if (r.status != Status.ok) return r;

      final url =
          'http://xsc.swust.edu.cn/Sys/SystemForm/Leave/StuAllLeaveManage.aspx';
      final response = await dio.get(
        url,
        options: Options(
          responseDecoder: gbkDecoder,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final soup = BeautifulSoup(response.data as String);
      final gridView = soup.find('table', id: 'GridView1');

      if (gridView == null) return StatusContainer(Status.fail, '加载失败');

      final tbody = gridView.find('tbody')!;
      final trs = tbody.findAll('tr').sublist(1);

      final result = <DailyLeaveDisplay>[];
      for (final row in trs) {
        final tds = row.findAll('td');
        final editUrl = tds[1].find('a')!.getAttrValue('href');
        if (editUrl == null) continue;
        final idRegex = RegExp(r'Id=([0-9]+)');
        final id = idRegex.firstMatch(editUrl)?.group(1);
        if (id == null) continue;

        final time = tds[2].text;
        final type = tds[3].text;
        final address = tds[4].text;
        final status = tds[5].text;
        final leaveStatus = tds[6].text;
        result.add(
          DailyLeaveDisplay(
            id: id,
            time: time,
            type: type,
            address: address,
            status: status,
            leaveStatus: leaveStatus,
          ),
        );
      }

      return StatusContainer(Status.ok, result);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取短信验证码
  ///
  /// [phone] 手机号
  /// 返回状态容器，成功时包含验证码发送结果
  Future<StatusContainer<String>> getDynamicCode(String phone) async {
    try {
      final response = await dio.post(
        'https://cas.swust.edu.cn/authserver/getDynamicCode',
        data: {'mobile': phone},
        options: Options(
          headers: {
            ...defaultHeaders,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Host': 'cas.swust.edu.cn',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final msg = data['msg'] as String? ?? '验证码发送成功';
          return StatusContainer(Status.ok, msg);
        }
        return StatusContainer(Status.ok, '验证码发送成功');
      } else {
        return StatusContainer(Status.fail, '发送验证码失败');
      }
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '发送验证码异常');
    }
  }

  /// 短信验证码登录
  ///
  /// [phone] 手机号
  /// [code] 验证码
  /// 返回状态容器，成功时包含登录结果
  Future<StatusContainer<String>> loginByPhone(String phone, String code) async {
    try {
      // 获取execution参数
      final loginResp = await dio.get(
        'https://cas.swust.edu.cn/authserver/login?service=https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=studentPortal:DEFAULT_EVENT',
        options: Options(
          headers: {
            ...defaultHeaders,
            'Host': 'cas.swust.edu.cn',
          },
        ),
      );

      final execution = RegExp(r'name="execution"\s+value="(.*?)"')
          .firstMatch(loginResp.data as String)
          ?.group(1);

      if (execution == null) {
        return StatusContainer(Status.fail, '获取登录参数失败');
      }

      final loginData = {
        'execution': execution,
        '_eventId': 'submit',
        'geolocation': '',
        'username': phone,
        'lm': 'dynamicLogin',
        'dynamicCode': code,
        'submit': ''
      };

      final response = await dio.post(
        'https://cas.swust.edu.cn/authserver/login',
        data: loginData,
        options: Options(
          headers: {
            ...defaultHeaders,
            'Content-Type': 'application/x-www-form-urlencoded',
            'Host': 'cas.swust.edu.cn',
          },
          followRedirects: true,
        ),
      );

      if (response.statusCode == 302) {
        final location = response.headers.value('Location');
        if (location != null && location.contains('matrix.dean.swust.edu.cn')) {
          final cookies = response.headers.map['set-cookie'];
          if (cookies != null) {
            for (final cookie in cookies) {
              if (cookie.contains('TGC=')) {
                final tgcMatch = RegExp(r'TGC=([^;]+)').firstMatch(cookie);
                if (tgcMatch != null) {
                  final tgc = tgcMatch.group(1);
                  return StatusContainer(Status.ok, tgc!);
                }
              }
            }
          }
          return StatusContainer(Status.ok, '登录成功');
        }
      }

      // 检查错误信息
      final responseText = response.data as String;
      if (responseText.contains('验证码错误') ||
          responseText.contains('验证码不正确') ||
          responseText.contains('验证码输入错误')) {
        return StatusContainer(Status.fail, '验证码错误');
      }

      if (responseText.contains('手机号不存在') ||
          responseText.contains('用户不存在')) {
        return StatusContainer(Status.fail, '手机号未注册');
      }

      return StatusContainer(Status.fail, '登录失败');
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '登录异常');
    }
  }

  /// ==================== 教评相关方法 ====================

  /// 获取待评教课程列表
  Future<List<EvaluationPaper>> getEvaluationPaperList() async {
    const url =
        'https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=evaluateOnline:DEFAULT_EVENT';
    
    try {
      final res = await dio.get(url);
      final document = BeautifulSoup(res.data);
      final evaluationList = <EvaluationPaper>[];
      const baseurl = "https://matrix.dean.swust.edu.cn/acadmicManager/";
      
      final evaluationRawData = document.findAll('tr', class_: 'editRows');

      for (var item in evaluationRawData) {
        try {
          final tds = item.findAll('td');
          if (tds.length < 3) continue;
          
          String info = tds[2].text.trim();
          // 移除多余的空格,但保留用于分隔的空格
          info = info.replaceAll(RegExp(r'\s+'), ' ');
          
          // 使用最后一个 " - " (包含空格)作为分隔符
          // 这样可以正确处理课程名中包含 "-" 的情况,如 "大学体育3-保健体育 - 王东辉"
          final lastSeparatorIndex = info.lastIndexOf(' - ');
          if (lastSeparatorIndex == -1) {
            // 如果没有 " - ",尝试使用 "-" 分隔
            final separatorIndex = info.lastIndexOf('-');
            if (separatorIndex == -1) continue;
            
            final course = info.substring(0, separatorIndex).trim();
            final teacher = info.substring(separatorIndex + 1).trim();
            
            if (course.isEmpty || teacher.isEmpty) continue;
            
            final infoLink = item.find('a', class_: 'info');
            if (infoLink == null || infoLink['href'] == null) continue;

            evaluationList.add(EvaluationPaper(
              college: tds[1].text.trim(),
              course: course,
              teacher: teacher,
              url: baseurl + infoLink['href']!,
            ));
          } else {
            final course = info.substring(0, lastSeparatorIndex).trim();
            final teacher = info.substring(lastSeparatorIndex + 3).trim(); // +3 跳过 " - "
            
            if (course.isEmpty || teacher.isEmpty) continue;

            final infoLink = item.find('a', class_: 'info');
            if (infoLink == null || infoLink['href'] == null) continue;

            evaluationList.add(EvaluationPaper(
              college: tds[1].text.trim(),
              course: course,
              teacher: teacher,
              url: baseurl + infoLink['href']!,
            ));
          }
        } catch (e) {
          continue;
        }
      }
      
      return evaluationList;
    } catch (e) {
      return [];
    }
  }

  /// 解析评价页面，提取表单数据和选项信息
  /// [data] 包含课程 URL 的字典
  /// [value] 评分等级（1-4）
  Future<Map<String, dynamic>> parseEvaluation(
      Map<String, dynamic> data, int value) async {
    final url = data['url'];
    
    try {
      final res = await dio.get(url);
      final document = BeautifulSoup(res.data);

      String getInputValue(String name) {
        final input = document.find('input', attrs: {'name': name});
        return input?['value'] ?? '';
      }

      final scc = getInputValue('SCC');
      final stage = getInputValue('Stage');
      final mode = getInputValue('Mode');
      final teacherId = getInputValue('TeacherID');
      final courseId = getInputValue('CourseID');
      final title = getInputValue('Title');
      final tid = getInputValue('TID');
      final tsk = getInputValue('TSK');

      final courseInfo = {
        "Mode": mode,
        "Stage": stage,
        "TeacherID": teacherId,
        "CourseID": courseId,
        "Title": title,
        "TID": tid,
        "SCC": scc,
        "TSK": tsk
      };

      final rawLinks = document.findAll('a', attrs: {'data-opt': '$value'});
      final outData = [];

      for (var link in rawLinks) {
        final href = link['href'];
        if (href == null) continue;
        
        final jsCode = href.replaceAll(' ', '').replaceAll("');", '');
        if (!jsCode.contains("postQuota('")) continue;
        
        final chooseData = jsCode.split("postQuota('")[1].split("','");
        if (chooseData.length < 3) continue;
        
        outData.add({
          "TAG": chooseData[0],
          "OPT": value,
          "ST": chooseData[2],
          "SCC": scc,
          "seed": DateTime.now().millisecondsSinceEpoch,
          "data": data
        });
      }

      return {"courseInfo": courseInfo, "opts": outData};
    } catch (e) {
      return {"courseInfo": {}, "opts": []};
    }
  }

  Future<bool> evaluateOption(Map<String, dynamic> option) async {
    const url =
        "https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=evaluateOnline:apiPostQuota";

    try {

      final response = await dio.post(
        url,
        data: FormData.fromMap(option),
        options: Options(
          headers: {
            "accept":
                "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "accept-language": "zh-CN,zh;q=0.9",
            "cache-control": "max-age=0",
            "content-type": "application/x-www-form-urlencoded",
            "origin": "https://matrix.dean.swust.edu.cn",
            "priority": "u=0, i",
            "referer":
                "https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=evaluateOnline:evaluateResponse",
            "sec-ch-ua":
                "\"Google Chrome\";v=\"131\", \"Chromium\";v=\"131\", \"Not_A Brand\";v=\"24\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"Windows\"",
            "sec-fetch-dest": "document",
            "sec-fetch-mode": "navigate",
            "sec-fetch-site": "same-origin",
            "sec-fetch-user": "?1",
            "upgrade-insecure-requests": "1",
            "user-agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
          },
        ),
      );

      final resultString = response.data;
      if (resultString is String) {
        try {
          final result = jsonDecode(resultString);
          if (result['success'] == true) {
            return true;
          }
        } catch (e) {
          return false;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> submitEvaluation(Map<String, dynamic> courseInfo) async {
    const url = "https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm";
    final params = {"event": "evaluateOnline:evaluateResponseDo"};
    
    try {

      final response = await dio.post(
        url,
        data: FormData.fromMap(courseInfo),
        queryParameters: params,
        options: Options(
          headers: {
            "accept":
                "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "accept-language": "zh-CN,zh;q=0.9",
            "cache-control": "max-age=0",
            "content-type": "application/x-www-form-urlencoded",
            "origin": "https://matrix.dean.swust.edu.cn",
            "priority": "u=0, i",
            "referer":
                "https://matrix.dean.swust.edu.cn/acadmicManager/index.cfm?event=evaluateOnline:evaluateResponse",
            "sec-ch-ua":
                "\"Google Chrome\";v=\"131\", \"Chromium\";v=\"131\", \"Not_A Brand\";v=\"24\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"Windows\"",
            "sec-fetch-dest": "document",
            "sec-fetch-mode": "navigate",
            "sec-fetch-site": "same-origin",
            "sec-fetch-user": "?1",
            "upgrade-insecure-requests": "1",
            "user-agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
          },
          validateStatus: (status) {
            return status != null && (status >= 200 && status < 300 || status == 302);
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 302) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// 执行单个课程的完整评价流程
  /// [evaluation] 课程数据字典
  /// [courseComment] 评论内容
  /// [value] 评分等级（1-4）
  Future<bool> evaluateOne(
      Map<String, dynamic> evaluation, String courseComment, int value) async {
    try {
      final parsedData = await parseEvaluation(evaluation, value);
      final courseInfo = parsedData['courseInfo'] as Map<String, dynamic>;
      final opts = parsedData['opts'] as List;

      courseInfo['CourseComment'] = courseComment;

      for (var opt in opts) {
        await evaluateOption(opt);
      }

      return await submitEvaluation(courseInfo);
    } catch (e) {
      return false;
    }
  }

  /// 批量评价所有课程
  /// [courseComment] 评论内容
  /// [value] 评分等级（1-4，1=非常满意，2=满意，3=一般，4=不满意）
  Future<Map<String, dynamic>> evaluateAll({
    String courseComment = "无",
    int value = 1,
  }) async {
    try {
      final evaluationList = await getEvaluationPaperList();
      
      if (evaluationList.isEmpty) {
        return {
          'success': false,
          'message': '没有待评价的课程',
          'total': 0,
          'completed': 0,
        };
      }

      int completed = 0;
      for (var evaluation in evaluationList) {
        final success = await evaluateOne(evaluation.toJson(), courseComment, value);
        if (success) {
          completed++;
        }
      }

      return {
        'success': true,
        'message': '评价完成',
        'total': evaluationList.length,
        'completed': completed,
      };
    } catch (e) {

      return {
        'success': false,
        'message': '批量评价失败: $e',
        'total': 0,
        'completed': 0,
      };
    }
  }
}
