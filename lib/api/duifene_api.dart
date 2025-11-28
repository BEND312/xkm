import 'dart:convert';
import 'dart:math';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:swustmeow/entity/duifene/duifene_course.dart';
import 'package:swustmeow/entity/duifene/duifene_homework.dart';
import 'package:swustmeow/entity/duifene/duifene_test.dart';
import 'package:swustmeow/entity/duifene/sign/sign_types/duifene_location_sign.dart';
import 'package:swustmeow/entity/duifene/sign/sign_types/duifene_sign_base.dart';
import 'package:swustmeow/entity/duifene/sign/sign_types/duifene_sign_code_sign.dart';
import 'package:swustmeow/utils/math.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/utils/text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swustmeow/utils/time.dart';

class DuiFenEApiService {
  final _dio = Dio();
  final _host = 'https://www.duifene.com';
  late PersistCookieJar _cookieJar;

  Future<void> init() async {
    await _initializeCookieJar();
    _dio.options.headers = {
      'User-Agent':
          'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 MicroMessenger/8.0.40(0x1800282a) NetType/WIFI Language/zh_CN',
    };
    _dio.options.validateStatus = (status) => true; // 忽略证书验证
    _dio.options.sendTimeout = const Duration(seconds: 10);
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

  /// 登录到对分易
  ///
  /// 只会返回一个是否登录成功的状态。
  Future<StatusContainer> login(String username, String password) async {
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'Referer': '$_host/Home.aspx',
    };
    final params =
        'action=loginmb&loginname=$username&password=$password&issave=false&guid=';

    try {
      await _cookieJar.deleteAll();
      await _dio.get('$_host/Home.aspx');

      final response = await _dio.post(
        '$_host/AppCode/LoginInfo.ashx',
        data: params,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final body = response.data.toString();
        if (body.contains('登录成功')) {
          return const StatusContainer(Status.ok);
        }

        try {
          final respJson = json.decode(response.data);
          final msg = respJson is Map ? respJson['msgbox'] : null;
          return StatusContainer(Status.fail, msg ?? '服务器错误');
        } catch (e) {
          return StatusContainer(Status.fail, '无法解析服务器请求');
        }
      } else {
        return const StatusContainer(Status.notAuthorized);
      }
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }
  }

  /// 获取课程名称列表
  ///
  /// 若中途遇到异常，返回错误信息字符串的状态容器；
  /// 否则正常返回 [DuiFenECourse] 的列表的状态容器。
  Future<StatusContainer<dynamic>> getCourseList() async {
    final cookie = await cookieString;
    final headers = {
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'Referer': '$_host/_UserCenter/PC/CenterStudent.aspx',
      'Cookie': cookie,
    };
    const params = 'action=getstudentcourse&classtypeid=2';

    try {
      final response = await _dio.post(
        '$_host/_UserCenter/CourseInfo.ashx',
        data: params,
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final info = json.decode(response.data);

        if (info != null) {
          if (info is List) {
            List<DuiFenECourse> result = [];
            for (Map<String, dynamic> map in info) {
              final instance = DuiFenECourse.fromJson(map);
              result.add(instance);
            }

            return StatusContainer(Status.ok, result);
          } else {
            await _cookieJar.deleteAll();
            return StatusContainer(Status.fail, info['msgbox']);
          }
        }
      }
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, e.toString());
    }

    return const StatusContainer(Status.fail);
  }

  /// 获取是否已登录状态
  Future<bool> getIsLogin() async {
    try {
      final cookie = await cookieString;
      final headers = {
        'Referer': 'https://www.duifene.com/_UserCenter/PC/CenterStudent.aspx',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Cookie': cookie
      };

      final response = await _dio.get('$_host/AppCode/LoginInfo.ashx',
          data: 'Action=checklogin', options: Options(headers: headers));

      Map<String, dynamic> data =
          (json.decode(response.data) as Map<dynamic, dynamic>).cast();
      if (response.statusCode == 200) {
        if (data['msg'] == '1') {
          return true;
        } else {
          await _cookieJar.deleteAll();
          return false;
        }
      }

      return false;
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  /// 转到签到页面
  ///
  /// 返回一个是否成功的值。
  Future<bool> _goSign(DuiFenECourse course) async {
    try {
      final cookie = await cookieString;
      final headers = {
        'Referer': 'https://www.duifene.com/_UserCenter/MB/index.aspx',
        'Cookie': cookie
      };

      final response = await _dio.head(
          '$_host/_UserCenter/MB/Module.aspx?data=${course.courseId}',
          options: Options(headers: headers));
      return response.statusCode == 200;
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return false;
    }
  }

  /// 检查是否有签到，返回一个签到信息
  Future<StatusContainer<DuiFenESignBase>> checkSignIn(
      DuiFenECourse course) async {
    try {
      final flag = await _goSign(course);
      if (!flag) return const StatusContainer(Status.notAuthorized);

      final cookie = await cookieString;
      final headers = {
        'Cookie': cookie,
      };

      final response = await _dio.get(
        '$_host/_CheckIn/MB/TeachCheckIn.aspx?classid=${course.tClassId}&temps=0&checktype=1&isrefresh=0&timeinterval=0&roomid=0&match=',
        options: Options(headers: headers),
      );

      String text = response.data as String;
      if (response.statusCode != 200) {
        return const StatusContainer(Status.notAuthorized);
      }

      final soup = BeautifulSoup(text);
      final seconds = soup.find('*', id: 'HFSeconds')?.getAttrValue('value');
      final checkType =
          soup.find('*', id: 'HFChecktype')?.getAttrValue('value');
      final checkInId =
          soup.find('*', id: 'HFCheckInID')?.getAttrValue('value');
      final classId = soup.find('*', id: 'HFClassID')?.getAttrValue('value');

      if (classId?.contains(course.tClassId) != true) {
        return const StatusContainer(Status.fail);
      }

      if (checkInId == null || seconds == null) {
        return const StatusContainer(Status.fail);
      }

      if (checkType == '1') {
        // 签到码签到
        final signCode =
            soup.find('*', id: 'HFCheckCodeKey')?.getAttrValue('value');
        if (signCode == null) return StatusContainer(Status.fail);
        return StatusContainer(
          Status.ok,
          DuiFenESignCodeSign(
            id: checkInId,
            secondsRemaining: int.tryParse(seconds) ?? 0,
            signCode: signCode,
          ),
        );
      } else if (checkType == '3') {
        // 定位签到
        final longitude = tryParseDouble(
            soup.find('*', id: 'HFRoomLongitude')?.getAttrValue('value'));
        final latitude = tryParseDouble(
            soup.find('*', id: 'HFRoomLatitude')?.getAttrValue('value'));
        if (longitude == null || latitude == null) {
          return StatusContainer(Status.fail);
        }

        return StatusContainer(
          Status.ok,
          DuiFenELocationSign(
            id: checkInId,
            secondsRemaining: int.tryParse(seconds) ?? 0,
            longitude: longitude,
            latitude: latitude,
          ),
        );
      }

      return StatusContainer(Status.fail);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail);
    }
  }

  /// 获取用户 ID
  ///
  /// 返回用户 ID 的字符串的状态容器。
  Future<StatusContainer<String>> getUserId() async {
    try {
      final cookie = await cookieString;
      final headers = {'Cookie': cookie};

      final response = await _dio.get('$_host/_UserCenter/MB/index.aspx',
          options: Options(headers: headers));
      if (response.statusCode != 200) {
        return const StatusContainer(Status.notAuthorized);
      }

      final soup = BeautifulSoup(response.data as String);
      final id = soup.find('*', id: 'hidUID')?.getAttrValue('value');
      if (id == null) return const StatusContainer(Status.notAuthorized);

      return StatusContainer(Status.ok, id);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail);
    }
  }

  /// 签到码签到
  ///
  /// 返回一个带有消息的字符串状态容器。
  Future<StatusContainer<String>> signInWithSignCode(String signCode) async {
    try {
      if (signCode.length != 4) {
        return StatusContainer(Status.fail, '签到码格式错误');
      }

      final userIdContainer = await getUserId();
      if (userIdContainer.status != Status.ok ||
          userIdContainer.value == null) {
        return StatusContainer(Status.notAuthorized, '登录状态失效');
      }

      final cookie = await cookieString;
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Referer':
            'https://www.duifene.com/_CheckIn/MB/CheckInStudent.aspx?moduleid=16&pasd=',
        'Cookie': cookie,
      };
      final params =
          'action=studentcheckin&studentid=${userIdContainer.value}&checkincode=$signCode';

      final response = await _dio.post('$_host/_CheckIn/CheckIn.ashx',
          data: params, options: Options(headers: headers));
      final data = json.decode(response.data as String);
      final code = data['msg'] as int;
      String? msg = data['msgbox'] as String;
      final timeMatched =
          RegExp(r'(.+?)(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})').firstMatch(msg);
      if (timeMatched != null) msg = timeMatched.group(1);

      return StatusContainer(
        code == 1 ? Status.ok : Status.fail,
        timeMatched == null ? msg : timeMatched.group(1),
      );
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail);
    }
  }

  /// 定位签到
  ///
  /// 返回一个带有消息的字符串状态容器。
  Future<StatusContainer<String>> signInWithLocation(
      double longitude, double latitude) async {
    try {
      double generateRandomOffset() {
        // 生成-0.000089到0.000089之间的随机数
        return Random().nextDouble() * 0.000178 - 0.000089;
      }

      longitude =
          double.parse((longitude + generateRandomOffset()).toStringAsFixed(8));
      latitude =
          double.parse((latitude + generateRandomOffset()).toStringAsFixed(8));

      final userIdContainer = await getUserId();
      if (userIdContainer.status != Status.ok ||
          userIdContainer.value == null) {
        return StatusContainer(Status.notAuthorized, '登录状态失效');
      }

      final cookie = await cookieString;
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Referer':
            'https://www.duifene.com/_CheckIn/MB/CheckInStudent.aspx?moduleid=16&pasd=',
        'Cookie': cookie,
      };
      final params =
          'action=signin&sid=${userIdContainer.value}&longitude=$longitude&latitude=$latitude';

      final response = await _dio.post(
          '$_host/_CheckIn/CheckInRoomHandler.ashx',
          data: params,
          options: Options(headers: headers));
      if (response.statusCode != 200) {
        return StatusContainer(Status.fail, '签到失败');
      }

      final data = json.decode(response.data as String);
      String? msg = data['msgbox'] as String?;
      final success = msg?.contains('成功') ?? false;

      return StatusContainer(success ? Status.ok : Status.fail, msg);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail);
    }
  }

  /// 获取在线练习
  ///
  /// 返回一个带有 [DuiFenETest] 的列表的状态容器。
  Future<StatusContainer<List<DuiFenETest>>> getTests(
      DuiFenECourse course) async {
    try {
      final cookie = await cookieString;
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Referer':
            'https://www.duifene.com/_Paper/MB/StudentPaperList.aspx?moduleid=19&pasd=',
        'Cookie': cookie,
      };
      final params = 'Action=datalist&CourseID=${course.courseId}';

      final response = await _dio.post('$_host/_Paper/StudentPaper.ashx',
          data: params, options: Options(headers: headers));
      if (response.statusCode != 200) {
        return const StatusContainer(Status.notAuthorized);
      }

      final data = json.decode(response.data as String) as Map<String, dynamic>;
      List<dynamic>? j = data['jsontb1'] as List<dynamic>?;
      if (j == null) return const StatusContainer(Status.fail);

      List<Map<String, dynamic>> testList = j.cast();
      List<DuiFenETest> result = [];
      for (final testJson in testList) {
        try {
          final myDone = (testJson['MyDoneDate'] as String).emptyThenNull;
          final myStatus = testJson['MyStatus'] as String;
          final test = DuiFenETest(
            course: course,
            name: testJson['Name'],
            createTime: tryParseFlexible(testJson['CreateDate'])!,
            beginTime: tryParseFlexible(testJson['BeginDate']),
            endTime: tryParseFlexible(testJson['EndDate'])!,
            submitTime: myDone != null ? tryParseFlexible(myDone) : null,
            limitMinutes: int.parse(testJson['LimitTime']),
            creatorName: testJson['CreateName'],
            score: double.parse(testJson['MyScore']).toInt(),
            finished: myStatus.isNotEmpty && myStatus != '0',
            overdue: testJson['OverDue'] == '1',
          );
          result.add(test);
        } catch (_) {}
      }

      return StatusContainer(Status.ok, result);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail);
    }
  }

  /// 获取所有作业
  ///
  /// 返回一个带有 [DuiFenEHomework] 的列表的状态容器。
  Future<StatusContainer<List<DuiFenEHomework>>> getHomeworks(
      DuiFenECourse course) async {
    try {
      final cookie = await cookieString;
      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Referer':
            'https://www.duifene.com/_HomeWork/MB/StudentHomeWork.aspx?moduleid=12&pasd=',
        'Cookie': cookie,
      };
      final params =
          'action=gethomeworklist&courseid=${course.courseId}&classtypeid=2&classid=${course.tClassId}&mathradom=';

      final response = await _dio.post('$_host/_HomeWork/HomeWorkInfo.ashx',
          data: params, options: Options(headers: headers));
      if (response.statusCode != 200) {
        return const StatusContainer(Status.notAuthorized);
      }

      final data = json.decode(response.data as String) as List<dynamic>;
      List<Map<String, dynamic>> list = data.cast();

      List<DuiFenEHomework> result = [];
      for (final hwJson in list) {
        try {
          final hw = DuiFenEHomework(
            course: course,
            name: hwJson['HWName'],
            endTime: tryParseFlexible(
                (hwJson['EndDate'] as String).replaceAll('/', '-'))!,
            finished: hwJson['IsSubmit'] == '1',
            overdue: hwJson['OverDue'] == '1',
          );
          result.add(hw);
        } catch (_) {}
      }

      return StatusContainer(Status.ok, result);
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail);
    }
  }
}
