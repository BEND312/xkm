import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swustmeow/dio_cookie_interceptor.dart';
import 'package:swustmeow/entity/apaertment/apartment_student_info.dart';
import 'package:swustmeow/entity/apaertment/electricity_bill.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/utils/text.dart';
import 'package:swustmeow/utils/time.dart';

import '../entity/apaertment/apartment_auth_token.dart';
import '../services/boxes/apartment_box.dart';

class ApartmentApiService {
  final _dio = Dio();
  static const ua =
      'Mozilla/5.0 (Linux; Android 13; TX6s) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.6783.58 Mobile Safari/537.36';
  late PersistCookieJar _cookieJar;

  Future<void> init() async {
    await _initializeCookieJar();
    _dio.options.headers = {
      'User-Agent': ua,
      'Accept-Language':
          'zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2',
      'Content-Type': 'application/json',
    };
    _dio.options.validateStatus = (status) => true; // 忽略证书验证
    _dio.options.sendTimeout = const Duration(seconds: 10);
    _dio.interceptors.add(DioCookieInterceptor(key: 'apartment'));
  }

  Future<void> _initializeCookieJar() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiesPath = '${appDocDir.path}/cookies';
    _cookieJar = PersistCookieJar(storage: FileStorage(cookiesPath));
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<void> deleteCookies() async {
    await _cookieJar.deleteAll();
  }

  StatusContainer<dynamic> _getData(Response<dynamic> response) {
    if (response.statusCode == 401) {
      return StatusContainer(Status.notAuthorized, '登录失效');
    }

    if (response.statusCode != 200) {
      return StatusContainer(Status.fail, '错误代码${response.statusCode}');
    }

    final json = response.data as Map<String, dynamic>;
    final flag = (json['flag'] as bool?) == true;
    final msg = (json['msg'] as String?)?.emptyThenNull;
    final data = json['data'] as Map<String, dynamic>?;

    if (!flag || data == null) {
      return StatusContainer(Status.fail, msg ?? '未知错误');
    }

    return StatusContainer(Status.ok, data);
  }

  /// 登录到公寓中心
  ///
  /// 若登录成功，返回一个带有 [ApartmentAuthToken] 的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<dynamic>> login(
      String username, String password) async {
    try {
      final cacheToken = ApartmentBox.get('authToken') as ApartmentAuthToken?;
      if (cacheToken != null && cacheToken.expireDate > DateTime.now()) {
        return StatusContainer(Status.ok, cacheToken);
      }

      await _dio.get('http://gydb.swust.edu.cn/sgH5/login.html');

      final payload = {
        'username': username,
        'password': md5.convert(utf8.encode(password)).toString(),
      };

      final loginUrl = 'http://gydb.swust.edu.cn/AppApi/api/login';
      final response = await _dio.post(loginUrl, data: payload);
      final dataResult = _getData(response);
      if (dataResult.status != Status.ok) return dataResult;
      final data = dataResult.value as Map<String, dynamic>;

      final accessToken = data['access_token'] as String?;
      final tokenType = data['token_type'] as String?;
      final expires = data['.expires'] as String?;

      if (accessToken == null || tokenType == null || expires == null) {
        return StatusContainer(Status.fail, '登录失败');
      }

      final expireDate = DateFormat('EEE, d MMM yyyy HH:mm:ss')
          .parse(expires)
          .add(Duration(hours: 8));

      return StatusContainer(
        Status.ok,
        ApartmentAuthToken(
          tokenType: tokenType,
          token: accessToken,
          expireDate: expireDate,
        ),
      );
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '登录失败');
    }
  }

  /// 获取电费
  ///
  /// 若获取成功，返回一个带有 [ElectricityBill] 的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<dynamic>> getElectricityBill(
      String authorization) async {
    try {
      final response = await _dio.post(
          'http://gydb.swust.edu.cn/AppApi/api/cost/search_dianfei',
          options: Options(headers: {'Authorization': authorization}));
      final dataResult = _getData(response);
      if (dataResult.status != Status.ok) return dataResult;
      final data = dataResult.value as Map<String, dynamic>;

      final roomName = data['roomname'] as String;
      final remaining = data['roommoney'] as double;
      return StatusContainer(
          Status.ok, ElectricityBill(roomName: roomName, remaining: remaining));
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '获取失败');
    }
  }

  /// 获取学生详细信息
  ///
  /// 若获取成功，返回一个带有 [ApartmentStudentInfo] 的状态容器；
  /// 否则，返回一个带有错误信息字符串的状态容器。
  Future<StatusContainer<dynamic>> getStudentInfo(String authorization) async {
    try {
      final response = await _dio.get(
          'http://gydb.swust.edu.cn/AppApi/api/student/getstuinfo',
          options: Options(headers: {'Authorization': authorization}));
      final data = response.data as Map<String, dynamic>;

      final bedString = data['Bed'] as String;
      final roomName = bedString.split('-').sublist(0, 2).join('-');
      final bed = int.parse(bedString.split('-').last);
      final className = data['ClassName'] as String;
      final facultyName = data['FacultyName'] as String;
      final grade = int.parse(data['Grade'] as String);
      final isCheckIn = data['IsCheckIn'] == true;
      final realName = data['RealName'] as String;
      final studentNumber = data['StudentNumber'] as String;
      final studentTypeName = data['StudentTypeName'] as String;
      return StatusContainer(
        Status.ok,
        ApartmentStudentInfo(
          roomName: roomName,
          bed: bed,
          className: className,
          facultyName: facultyName,
          grade: grade,
          isCheckIn: isCheckIn,
          realName: realName,
          studentNumber: studentNumber,
          studentTypeName: studentTypeName,
        ),
      );
    } catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '获取失败');
    }
  }
}