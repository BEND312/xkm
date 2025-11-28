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

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:swustmeow/api/soa_api.dart';
import 'package:swustmeow/entity/ykt/ykt_auth_token.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/entity/ykt/ykt_card_account_info.dart';
import 'package:swustmeow/services/boxes/ykt_box.dart';
import 'package:swustmeow/services/boxes/soa_box.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/status.dart';

import '../dio_cookie_interceptor.dart';
import '../entity/ykt/ykt_bill.dart';
import '../entity/ykt/ykt_pay_app.dart';
import '../entity/ykt/ykt_secure_keyboard_data.dart';

class YKTApiService {
  final _dio = Dio();
  static const _host = 'http://ykt.swust.edu.cn';
  static const ua =
      'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36';
  static const defaultHeaders = {
    'User-Agent': ua,
    'Accept': '*/*',
    'Accept-Encoding': 'gzip, deflate, br',
  };
  late PersistCookieJar _cookieJar;

  Future<void> init() async {
    await _initializeCookieJar();
    _dio.options.headers = defaultHeaders;
    _dio.options.validateStatus = (status) => true; // 忽略证书验证
    _dio.options.sendTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.connectTimeout = const Duration(seconds: 10);

    // 修复 `CERTIFICATE_VERIFY_FAILED: unable to get local issuer certificate` 的问题
    // https://stackoverflow.com/a/60890158/15809316
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        () => HttpClient()..badCertificateCallback = (cert, host, port) => true;

    _dio.interceptors.add(DioCookieInterceptor(key: 'ykt'));
  }

  Future<void> _initializeCookieJar() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiesPath = '${appDocDir.path}/cookies';
    _cookieJar = PersistCookieJar(storage: FileStorage(cookiesPath));
    _dio.interceptors.add(CookieManager(_cookieJar));
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

  /// 登录到一卡通服务
  ///
  /// 成功时返回 ticket 字符串，失败时返回错误信息字符串
  Future<StatusContainer<String>> login({
    required String username,
    required String password,
    bool useSOATGC = false,
  }) async {
    try {
      final assertionResp = await _dio.get(
          '$_host/berserker-auth/cas/login/assertion?targetUrl=http%3A%2F%2Fykt.swust.edu.cn%2Fplat%3Fname%3DloginTransit%26source%3Dh5',
          options: Options(followRedirects: false));
      final location = assertionResp.headers.value('Location');
      if (location == null) {
        return const StatusContainer(Status.fail, '未成功获取请求（0）');
      }

      Response? resp;
      
      if (useSOATGC) {
        final tgc = SOABox.get<String>('tgc');
        if (tgc != null && tgc.isNotEmpty) {
          resp = await _dio.get(
            location,
            options: Options(
              followRedirects: false,
              headers: {
                'Cookie': 'TGC=$tgc',
                'Host': 'cas.swust.edu.cn',
              },
            ),
          );
          
          if (resp.statusCode != 302) {
            resp = null;
          }
        }
      }
      
      if (resp == null) {
        final loginResult = await SOAApiService.loginToSOA(
          dio: _dio,
          username: username,
          password: password,
          url: location,
        );
        final (loginResp, _) = loginResult.value!;
        if (loginResult.status != Status.ok || loginResp == null) {
          return StatusContainer(
              loginResult.status, loginResult.value?.$2 ?? '未知错误（1）');
        }
        resp = loginResp;
      }

      final location1 = resp.headers.value('Location');
      if (location1 == null) {
        return const StatusContainer(Status.fail, '未成功获取请求（1）');
      }

      final options = Options(
        followRedirects: false,
      );

      final assertionResp1 = await _dio.get(location1, options: options);
      final location2 = assertionResp1.headers.value('Location');
      if (location2 == null) {
        return const StatusContainer(Status.fail, '未成功获取请求（2）');
      }

      final assertionResp2 = await _dio.get(location2, options: options);
      final location3 = assertionResp2.headers.value('Location');
      if (location3 == null) {
        return const StatusContainer(Status.fail, '未成功获取请求（3）');
      }

      final platResp1 = await _dio.get(location3, options: options);
      final location4 = platResp1.headers.value('Location');
      if (location4 == null) {
        return const StatusContainer(Status.fail, '未成功获取请求（4）');
      }

      final ticket = Uri.parse(location4).queryParameters['ticket'];
      await _dio.get(location4, options: options);
      final ok = platResp1.statusCode == 200 || location4.isNotEmpty;

      return StatusContainer(
          ok ? Status.ok : Status.fail, ok ? ticket : '登录失败');
    } on Exception {
      return const StatusContainer(Status.fail, '登录异常');
    }
  }

  /// 退出登录
  Future<StatusContainer> logout() async {
    final token = YKTBox.get('token') as YKTAuthToken?;
    if (token == null) {
      return const StatusContainer(Status.fail);
    }

    final queryParams = {
      'type': 'logout',
      'loginFrom': 'h5',
      'synjones-auth': token.accessToken,
      'synAccessSource': 'h5',
    };
    await _dio.get(
      '$_host/berserker-base/redirect',
      queryParameters: queryParams,
    );
    return const StatusContainer(Status.ok);
  }

  /// 获取授权码
  ///
  /// 成功时返回 [YKTAuthToken]，失败时返回错误信息字符串
  Future<StatusContainer<dynamic>> getAuthToken() async {
    try {
      final ticket = YKTBox.get('ticket') as String?;
      if (ticket == null) {
        return const StatusContainer(Status.fail, '登录失效，请重新登录');
      }

      final params = {
        'username': ticket,
        'password': ticket,
        'grant_type': 'password',
        'scope': 'all',
        'loginFrom': 'h5',
        'logintype': 'sso',
        'device_token': 'h5',
        'synAccessSource': 'h5',
      };

      final headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        // 不知道哪来的 token
        'Authorization':
            'Basic bW9iaWxlX3NlcnZpY2VfcGxhdGZvcm06bW9iaWxlX3NlcnZpY2VfcGxhdGZvcm1fc2VjcmV0',
        'Referer': '$_host/plat/loginTransit?ticket=$ticket',
        'Host': 'ykt.swust.edu.cn',
      };

      final resp = await _dio.post(
        '$_host/berserker-auth/oauth/token',
        data: params,
        options: Options(headers: headers, followRedirects: false),
      );

      final data = resp.data as Map<String, dynamic>;
      final token = YKTAuthToken(
        accessToken: (data['access_token'] as String).trim(),
        refreshToken: (data['refresh_token'] as String).trim(),
        expiresIn: data['expires_in'],
        tokenType: (data['token_type'] as String).trim(),
        createdAt: DateTime.now(),
      );
      return StatusContainer(Status.ok, token);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return const StatusContainer(Status.fail, '获取一卡通令牌错误');
    }
  }

  Future<StatusContainer<dynamic>> _checkToken(
      Future<StatusContainer<dynamic>> Function(YKTAuthToken token)
          self) async {
    YKTAuthToken? token = YKTBox.get('token') as YKTAuthToken?;
    if (token == null || token.isExpired) {
      final reLoginResult = await GlobalService.yktService?.login();
      token = YKTBox.get('token') as YKTAuthToken?;
      if (reLoginResult == null ||
          reLoginResult.status != Status.ok ||
          token == null) {
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录（0）');
      }

      return await self(token);
    }
    return await self(token);
  }

  /// 获取所有一卡通的卡片
  ///
  /// 成功时返回卡片列表，失败时返回错误信息字符串
  Future<StatusContainer<dynamic>> getCards({
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录（1）');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getCards(token: t, retries: retries),
        );
      }

      final headers = {
        'Referer': '$_host/campus-card/campusCard?loginFrom=h5',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
      };

      final resp = await _dio.get(
        '$_host/berserker-app/ykt/tsm/getCampusCards?synAccessSource=h5',
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await getCards(token: token, retries: retries);
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取失败（${resp.statusCode}）');
      }

      final cards =
          (resp.data as Map<String, dynamic>)['data']['card'] as List<dynamic>;
      final result = <YKTCard>[];
      for (final card in cards) {
        final data = card as Map<String, dynamic>;
        final info = data['accinfo'] as List<dynamic>;
        final accountInfos = <YKTCardAccountInfo>[];
        for (final acc in info) {
          final accData = acc as Map<String, dynamic>;
          accountInfos.add(YKTCardAccountInfo(
            name: accData['name'] as String,
            type: accData['type'] as String,
            balance: ((accData['balance'] as int) / 100).toStringAsFixed(2),
          ));
        }

        result.add(YKTCard(
          account: data['account'] as String,
          cardName: data['cardname'] as String,
          departmentName: data['department_name'] as String,
          expireDate: (data['expdate'] as String).replaceAllMapped(
              RegExp(r'(\d{4})(\d{2})(\d{2})'),
              (match) => '${match[1]}/${match[2]}/${match[3]}'),
          name: data['name'] as String,
          accountInfos: accountInfos,
          isLocked: data['lostflag'] as int == 1,
        ));
      }

      return StatusContainer(Status.ok, result);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return const StatusContainer(Status.fail, '获取一卡通卡包错误');
    }
  }

  /// 根据卡账户和支付账户获取所有支付码
  ///
  /// 成功时返回一个 `List<String>`，否则返回错误信息字符串。
  Future<StatusContainer<dynamic>> getBarCodes({
    required String account,
    required String payAccount,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录（2）');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getBarCodes(
            account: account,
            payAccount: payAccount,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer':
            'http://ykt.swust.edu.cn/plat/pay?nodeId=15&synjones-auth=${token.accessToken}&loginFrom=h5',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
      };

      final resp = await _dio.get(
        // paytype：1 = 校园卡，2 = 银行卡
        '$_host/berserker-app/ykt/tsm/batchGetBarCodeGet?account=$account&payacc=$payAccount&paytype=1&synAccessSource=h5',
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await getBarCodes(
          account: account,
          payAccount: payAccount,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取失败（${resp.statusCode}）');
      }

      final data = (resp.data as Map<String, dynamic>)['data'];
      List<String> barcodes =
          ((data as Map<String, dynamic>)['barcode'] as List<dynamic>).cast();

      return StatusContainer(Status.ok, barcodes);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return const StatusContainer(Status.fail, '获取一卡通支付码错误');
    }
  }

  /// 获取一卡通账单数据
  ///
  /// 成功时返回 `List<YKTBill>`，否则返回错误信息字符串
  Future<StatusContainer<dynamic>> getBills({
    required String account,
    required String payAccount,
    int page = 1,
    int pageSize = 10,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录（3）');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getBills(
            account: account,
            payAccount: payAccount,
            page: page,
            pageSize: pageSize,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer': '$_host/campus-card/billing/list?loginFrom=h5',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
      };

      final resp = await _dio.get(
        '$_host/berserker-search/search/personal/turnover',
        queryParameters: {
          'size': pageSize,
          'current': page,
          'synAccessSource': 'h5',
        },
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await getBills(
          account: account,
          payAccount: payAccount,
          page: page,
          pageSize: pageSize,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200 || responseData['success'] != true) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '获取账单失败');
      }

      final data = responseData['data'] as Map<String, dynamic>;
      final records = data['records'] as List<dynamic>;

      List<YKTBill> bills = records.map((record) {
        return YKTBill.fromJson(record as Map<String, dynamic>);
      }).toList();

      return StatusContainer(Status.ok, bills);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return const StatusContainer(Status.fail, '获取一卡通账单错误');
    }
  }

  /// 获取指定时间段内的收支统计
  ///
  /// 成功时返回包含income和expenses的Map，否则返回错误信息字符串
  Future<StatusContainer<dynamic>> getStatistics({
    required String timeFrom,
    required String timeTo,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录（4）');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getStatistics(
            timeFrom: timeFrom,
            timeTo: timeTo,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer': '$_host/campus-card/billing/list?loginFrom=h5',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
      };

      final resp = await _dio.get(
        '$_host/berserker-search/statistics/turnover/count',
        queryParameters: {
          'timeFrom': timeFrom,
          'timeTo': timeTo,
          'synAccessSource': 'h5',
        },
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        return await getStatistics(
          timeFrom: timeFrom,
          timeTo: timeTo,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200 || responseData['success'] != true) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '获取统计数据失败');
      }

      final data = responseData['data'] as Map<String, dynamic>;
      return StatusContainer(Status.ok, {
        'income': data['income'] as double,
        'expenses': data['expenses'] as double,
      });
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return const StatusContainer(Status.fail, '获取一卡通统计数据错误');
    }
  }

  /// 挂失一卡通
  ///
  /// 成功时返回操作结果信息，失败时返回错误信息字符串
  Future<StatusContainer<dynamic>> lockCard({
    required String cardNo,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async =>
              await lockCard(cardNo: cardNo, token: t, retries: retries),
        );
      }

      final headers = {
        'Referer': '$_host/campus-card/cardOperation?loginFrom=h5',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
        'Content-Type': 'application/json;charset=UTF-8',
      };

      final data = {
        'account': cardNo,
      };

      final resp = await _dio.post(
        '$_host/berserker-app/ykt/tsm/lostCard',
        data: data,
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await lockCard(cardNo: cardNo, token: token, retries: retries);
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '操作失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200 || responseData['success'] != true) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '挂失操作失败');
      }

      // 操作成功
      final result = responseData['data'] as Map<String, dynamic>;
      return StatusContainer(Status.ok, result['errmsg'] ?? '挂失成功');
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return const StatusContainer(Status.fail, '挂失操作错误');
    }
  }

  /// 解挂一卡通
  ///
  /// 成功时返回操作结果信息，失败时返回错误信息字符串
  Future<StatusContainer<dynamic>> unlockCard({
    required String cardNo,
    required String password,
    required String keyboardId,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await unlockCard(
            cardNo: cardNo,
            password: password,
            keyboardId: keyboardId,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer': '$_host/campus-card/cardOperation?loginFrom=h5',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
        'Content-Type': 'application/json;charset=UTF-8',
      };

      // 按照要求格式拼接密码
      final formattedPassword = '1\$1\$$password\$1\$$keyboardId';

      final data = {
        'account': cardNo,
        'pwd': formattedPassword,
      };

      final resp = await _dio.post(
        '$_host/berserker-app/ykt/tsm/unlostCard',
        data: data,
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await unlockCard(
          cardNo: cardNo,
          password: password,
          keyboardId: keyboardId,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '操作失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200 || responseData['success'] != true) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '解挂操作失败');
      }

      // 操作成功，但需检查返回的 retcode
      final result = responseData['data'] as Map<String, dynamic>;
      final retcode = result['retcode'] as String;
      final errmsg = result['errmsg'] as String;

      if (retcode != '0') {
        return StatusContainer(Status.fail, errmsg);
      }

      return StatusContainer(Status.ok, errmsg);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return const StatusContainer(Status.fail, '解挂操作错误');
    }
  }

  /// 获取安全键盘
  ///
  /// 成功时返回键盘数据，失败时返回错误信息字符串
  Future<StatusContainer<dynamic>> getSecureKeyboard({
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getSecureKeyboard(
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer': '$_host/campus-card/cardOperation?loginFrom=h5',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
      };

      final resp = await _dio.get(
        '$_host/berserker-secure/keyboard',
        queryParameters: {
          'type': 'Number',
          'order': '1',
          'synAccessSource': 'h5',
        },
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await getSecureKeyboard(
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取安全键盘失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200 || responseData['success'] != true) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '获取安全键盘失败');
      }

      final keyboardData = responseData['data'] as Map<String, dynamic>;
      final keyboard = keyboardData['numberKeyboard'] as String;
      final base64Images = keyboardData['numberKeyboardImage'] as List<dynamic>;
      final images = base64Images.cast<String>();
      final uuid = keyboardData['uuid'] as String;

      return StatusContainer(
        Status.ok,
        YKTSecureKeyboardData(
          keyboard: keyboard,
          images: images,
          keyboardId: uuid,
        ),
      );
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return const StatusContainer(Status.fail, '获取安全键盘错误');
    }
  }

  /// 获取可缴费项目列表
  Future<StatusContainer<dynamic>> getPayApps({
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getPayApps(
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer': '$_host/plat/dating?index=1',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
      };

      final resp = await _dio.get(
        '$_host/berserker-app/appScheme/info',
        queryParameters: {
          'type': 'user',
          'serviceType': 'app',
          'synAccessSource': 'h5',
        },
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data['success'] == true) {
          final List<YKTPayApp> payApps = [];

          // 解析JSON获取livingExpenses组件下的应用
          final Map<String, dynamic> structureInfo =
              data['data']['structureInfo'];
          final List<dynamic> menuList =
              structureInfo['combinedMenuList'] ?? [];

          // 遍历查找livingExpenses组件
          for (final menu in menuList) {
            _findPayApps(menu, payApps);
          }

          return StatusContainer(Status.ok, payApps);
        } else {
          return StatusContainer(Status.fail, data['msg'] ?? '获取缴费列表失败');
        }
      } else {
        return StatusContainer(Status.fail, '获取缴费列表失败（${resp.statusCode}）');
      }
    } catch (e) {
      return StatusContainer(Status.fail, '获取缴费列表失败：$e');
    }
  }

  /// 递归查找livingExpenses组件下的缴费应用
  void _findPayApps(Map<String, dynamic> node, List<YKTPayApp> payApps) {
    // 检查当前节点是否为livingExpenses组件
    if (node['nodeType'] == 'component' &&
        node['comCode'] == 'livingExpenses') {
      final List<dynamic> apps = node['combinedAppList'] ?? [];
      for (final app in apps) {
        // 从website URL中提取feeItemId
        final String website = app['website'] ?? '';
        final String name = app['appName'] ?? '';

        // 使用正则表达式提取feeItemId
        final RegExp regExp = RegExp(r'feeitemid=(\d+)');
        final Match? match = regExp.firstMatch(website);

        if (match != null && match.groupCount >= 1) {
          final String feeItemId = match.group(1)!;
          payApps.add(YKTPayApp(name: name, feeItemId: feeItemId));
        }
      }
    }

    // 递归检查子节点
    final List<dynamic> components = node['combinedComponentList'] ?? [];
    for (final component in components) {
      _findPayApps(component, payApps);
    }

    final List<dynamic> apps = node['combinedAppList'] ?? [];
    for (final app in apps) {
      _findPayApps(app, payApps);
    }

    final List<dynamic> menus = node['combinedMenuList'] ?? [];
    for (final menu in menus) {
      _findPayApps(menu, payApps);
    }
  }

  /// 获取电费缴费数据（校区、楼栋、楼层、房间等）
  Future<StatusContainer<dynamic>> getElectricityData({
    required String level,
    required String feeItemId,
    String? campus,
    String? building,
    String? floor,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getElectricityData(
            level: level,
            feeItemId: feeItemId,
            campus: campus,
            building: building,
            floor: floor,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer':
            '$_host/charge-app/?name=pays&appsourse=ydfwpt&id=$feeItemId&paymentUrl=paymentUrl=http%253A%252F%252Fykt.swust.edu.cn%252Fplat&token=${token.accessToken}',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=',
      };

      // 根据级别构建不同的参数
      Map<String, dynamic> params = {
        'level': level,
        'type': 'select',
        'feeitemid': feeItemId,
      };

      // 添加条件参数
      if (campus != null) {
        params['campus'] = campus;
      }

      if (building != null) {
        params['building'] = building;
      }

      if (floor != null) {
        params['floor'] = floor;
      }

      final resp = await _dio.post(
        '$_host/charge/feeitem/getThirdData',
        data: params,
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await getElectricityData(
          level: level,
          feeItemId: feeItemId,
          campus: campus,
          building: building,
          floor: floor,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取数据失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '获取数据失败');
      }

      // 返回数据列表
      final data = (responseData['map'] as Map<String, dynamic>)['data']
          as List<dynamic>;
      return StatusContainer(Status.ok, data);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '获取电费缴费数据错误: $e');
    }
  }

  /// 获取用户信息
  Future<StatusContainer<dynamic>> getPaymentUserInfo({
    required String feeItemId,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getPaymentUserInfo(
            feeItemId: feeItemId,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer':
            '$_host/charge-app/?name=pays&appsourse=ydfwpt&id=$feeItemId&paymentUrl=http%253A%252F%252Fykt.swust.edu.cn%252Fplat&token=${token.accessToken}',
        'Authorization': 'Basic Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
      };

      final resp = await _dio.get(
        '$_host/charge/user/caslogin_userxx',
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await getPaymentUserInfo(
          feeItemId: feeItemId,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取用户信息失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '获取用户信息失败');
      }

      // 返回用户数据
      final userData = responseData['user'] as Map<String, dynamic>;
      return StatusContainer(Status.ok, userData);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '获取用户信息错误: $e');
    }
  }

  /// 获取电费数据的最终结果
  Future<StatusContainer<dynamic>> getElectricityFinalData({
    required String feeItemId,
    required String campus,
    required String building,
    required String floor,
    required String room,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getElectricityFinalData(
            feeItemId: feeItemId,
            campus: campus,
            building: building,
            floor: floor,
            room: room,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer':
            '$_host/charge-app/?name=pays&appsourse=ydfwpt&id=$feeItemId&paymentUrl=http%253A%252F%252Fykt.swust.edu.cn%252Fplat&token=${token.accessToken}',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=',
      };

      // 构建参数
      Map<String, dynamic> params = {
        'level': '4',
        'type': 'IEC',
        'feeitemid': feeItemId,
        'campus': campus,
        'building': building,
        'floor': floor,
        'room': room,
      };

      final resp = await _dio.post(
        '$_host/charge/feeitem/getThirdData',
        data: params,
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await getElectricityFinalData(
          feeItemId: feeItemId,
          campus: campus,
          building: building,
          floor: floor,
          room: room,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取数据失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '获取数据失败');
      }

      // 返回最终结果数据
      final map = responseData['map'] as Map<String, dynamic>;
      return StatusContainer(Status.ok, map);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '获取电费最终数据错误: $e');
    }
  }

  /// 获取支付前的订单信息
  ///
  /// 成功时返回订单ID字符串，失败时返回错误信息
  Future<StatusContainer<dynamic>> getPaymentOrderInfo({
    required String feeItemId,
    required String amount,
    required Map<String, dynamic> roomData,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getPaymentOrderInfo(
            feeItemId: feeItemId,
            amount: amount,
            roomData: roomData,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer':
            '$_host/charge-app/?name=pays&appsourse=ydfwpt&id=$feeItemId&paymentUrl=http%253A%252F%252Fykt.swust.edu.cn%252Fplat&token=${token.accessToken}',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=',
      };

      // 构建请求参数
      final Map<String, dynamic> params = {
        'feeitemid': feeItemId,
        'tranamt': amount,
        'flag': 'choose',
        'source': 'app',
        'paystep': '0',
        'abstracts': '',
        'third_party': json.encode(roomData),
      };

      final resp = await _dio.post(
        '$_host/blade-pay/pay',
        data: params,
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await getPaymentOrderInfo(
          feeItemId: feeItemId,
          amount: amount,
          roomData: roomData,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取订单信息失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200 || responseData['success'] != true) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '获取订单信息失败');
      }

      // 提取订单ID
      final data = responseData['data'] as Map<String, dynamic>;
      final orderId = data['orderid'] as String;

      return StatusContainer(Status.ok, orderId);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '获取支付订单信息错误: $e');
    }
  }

  /// 获取详细的支付信息
  ///
  /// 成功时返回包含支付类型ID和支付类型代码的Map，失败时返回错误信息
  Future<StatusContainer<dynamic>> getDetailedPaymentInfo({
    required String feeItemId,
    required String orderId,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getDetailedPaymentInfo(
            feeItemId: feeItemId,
            orderId: orderId,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer':
            '$_host/charge-app/?name=pays&appsourse=ydfwpt&id=$feeItemId&paymentUrl=http%253A%252F%252Fykt.swust.edu.cn%252Fplat&token=${token.accessToken}',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
        'Authorization': 'Basic Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=',
      };

      final resp = await _dio.get(
        '$_host/charge/pay/getpayinfo',
        queryParameters: {
          'orderid': orderId,
        },
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await getDetailedPaymentInfo(
          feeItemId: feeItemId,
          orderId: orderId,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取支付信息失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '获取支付信息失败');
      }

      // 提取payList中的第一个支付方式
      final payList = responseData['payList'] as List<dynamic>;
      if (payList.isEmpty) {
        return const StatusContainer(Status.fail, '没有可用的支付方式');
      }

      final firstPayMethod = payList[0] as Map<String, dynamic>;

      // 构建返回Map
      final resultMap = {
        'paytypeid': (firstPayMethod['payid'] as int).toString(),
        'paytype': firstPayMethod['code'],
        'name': firstPayMethod['name'],
      };

      return StatusContainer(Status.ok, resultMap);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '获取详细支付信息错误: $e');
    }
  }

  /// 获取确认付款的密码映射和账户信息
  ///
  /// 成功时返回包含余额、账户类型和密码映射的Map，失败时返回错误信息
  Future<StatusContainer<dynamic>> getPaymentConfirmInfo({
    required String feeItemId,
    required String orderId,
    required String payTypeId,
    required String payType,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await getPaymentConfirmInfo(
            feeItemId: feeItemId,
            orderId: orderId,
            payTypeId: payTypeId,
            payType: payType,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer':
            '$_host/charge-app/?name=pays&appsourse=ydfwpt&id=$feeItemId&paymentUrl=http%253A%252F%252Fykt.swust.edu.cn%252Fplat&token=${token.accessToken}',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=',
      };

      // 构建请求参数
      final Map<String, dynamic> params = {
        'orderid': orderId,
        'paytypeid': payTypeId,
        'paytype': payType,
        'paystep': '2',
      };

      final resp = await _dio.post(
        '$_host/blade-pay/pay',
        data: params,
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await getPaymentConfirmInfo(
          feeItemId: feeItemId,
          orderId: orderId,
          payTypeId: payTypeId,
          payType: payType,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '获取付款确认信息失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200 || responseData['success'] != true) {
        return StatusContainer(
            Status.fail, responseData['msg'] ?? '获取付款确认信息失败');
      }

      final data = responseData['data'] as Map<String, dynamic>;

      // 提取ccctype信息
      final ccctypeList = data['ccctype'] as List<dynamic>;
      if (ccctypeList.isEmpty) {
        return const StatusContainer(Status.fail, '账户信息不可用');
      }

      final firstAccount = ccctypeList[0] as Map<String, dynamic>;
      final balance = firstAccount['balance'] as double;
      final accountType = firstAccount['ccctype'] as String;

      // 提取passwordMap
      final passwordMap = data['passwordMap'] as Map<String, dynamic>;

      // 构建返回结果
      final resultMap = {
        'balance': balance.toString(),
        'accountType': accountType,
        'passwordMap': passwordMap,
      };

      return StatusContainer(Status.ok, resultMap);
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '获取付款确认信息错误: $e');
    }
  }

  /// 删除支付订单
  ///
  /// 成功时返回成功状态，失败时返回错误信息字符串
  Future<StatusContainer<dynamic>> deletePaymentOrder({
    required String feeItemId,
    required String orderId,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await deletePaymentOrder(
            feeItemId: feeItemId,
            orderId: orderId,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer':
            '$_host/charge-app/?name=pays&appsourse=ydfwpt&id=$feeItemId&paymentUrl=http%253A%252F%252Fykt.swust.edu.cn%252Fplat&token=${token.accessToken}',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
        'Content-Type': 'application/json;charset=UTF-8',
        'Authorization': 'Basic Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=',
      };

      // 构建请求数据
      final data = {'orderid': orderId};

      final resp = await _dio.post(
        '$_host/charge/order/deleteOrder',
        data: data,
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await deletePaymentOrder(
          feeItemId: feeItemId,
          orderId: orderId,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '删除订单失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '删除订单失败');
      }

      return const StatusContainer(Status.ok, '删除订单成功');
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '删除订单错误: $e');
    }
  }

  /// 执行最终支付操作
  ///
  /// 成功时返回支付结果，失败时返回错误信息字符串
  Future<StatusContainer<dynamic>> executePayment({
    required String feeItemId,
    required String orderId,
    required String payTypeId,
    required String payType,
    required String password,
    required String keyboardId,
    required String accountType,
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    try {
      if (retries <= 0) {
        await GlobalService.yktService?.logout(notify: true);
        return const StatusContainer(Status.fail, '登录状态失效，请重新登录');
      }
      retries--;
      if (token == null) {
        return _checkToken(
          (t) async => await executePayment(
            feeItemId: feeItemId,
            orderId: orderId,
            payTypeId: payTypeId,
            payType: payType,
            password: password,
            keyboardId: keyboardId,
            accountType: accountType,
            token: t,
            retries: retries,
          ),
        );
      }

      final headers = {
        'Referer':
            '$_host/charge-app/?name=pays&appsourse=ydfwpt&id=$feeItemId&paymentUrl=http%253A%252F%252Fykt.swust.edu.cn%252Fplat&token=${token.accessToken}',
        'Synjones-Auth': '${token.tokenType} ${token.accessToken}',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic Y2hhcmdlOmNoYXJnZV9zZWNyZXQ=',
      };

      // 构建请求参数
      final Map<String, dynamic> params = {
        'orderid': orderId,
        'paystep': '2',
        'paytype': payType,
        'paytypeid': payTypeId,
        'ccctype': accountType,
        'password': password,
        'uuid': keyboardId,
        'isWX': '0',
      };

      final resp = await _dio.post(
        '$_host/blade-pay/pay',
        data: params,
        options: Options(
          headers: headers,
          preserveHeaderCase: true,
        ),
      );

      if (resp.statusCode == 401) {
        // 登录状态失效，尝试重新登录
        await GlobalService.yktService?.login();
        token = YKTBox.get('token') as YKTAuthToken?;
        return await executePayment(
          feeItemId: feeItemId,
          orderId: orderId,
          payTypeId: payTypeId,
          payType: payType,
          password: password,
          keyboardId: keyboardId,
          accountType: accountType,
          token: token,
          retries: retries,
        );
      }

      if (resp.statusCode != 200) {
        return StatusContainer(Status.fail, '支付请求失败（${resp.statusCode}）');
      }

      final responseData = resp.data as Map<String, dynamic>;
      if (responseData['code'] != 200 && !responseData['success']) {
        return StatusContainer(Status.fail, responseData['msg'] ?? '支付失败');
      }

      // 支付成功
      return StatusContainer(Status.ok, responseData['data'] ?? '支付成功');
    } on Exception catch (e, st) {
      debugPrintStack(stackTrace: st);
      return StatusContainer(Status.fail, '支付操作错误: $e');
    }
  }
}
