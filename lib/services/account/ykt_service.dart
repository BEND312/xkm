import 'package:flutter/material.dart';
import 'package:swustmeow/api/ykt_api.dart';
import 'package:swustmeow/components/login_pages/ykt_login_page.dart';
import 'package:swustmeow/entity/account.dart';
import 'package:swustmeow/entity/ykt/ykt_auth_token.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/services/account/account_service.dart';
import 'package:swustmeow/services/boxes/ykt_box.dart';
import 'package:swustmeow/services/color_service.dart';

import '../../entity/button_state.dart';
import '../../utils/color.dart';
import '../../utils/status.dart';
import '../global_service.dart';

class YKTService extends AccountService<YKTLoginPage> {
  YKTApiService? _api;

  @override
  String get name => '一卡通';

  @override
  Account? get currentAccount => YKTBox.get('account') as Account?;

  @override
  List<Account> get savedAccounts =>
      (YKTBox.get('accounts') as List<dynamic>? ?? []).cast();

  @override
  bool get isLogin =>
      ((YKTBox.get('isLogin') as bool?) ?? false) && currentAccount != null;

  @override
  ValueNotifier<bool> isLoginNotifier =
      ValueNotifier(YKTBox.get('isLogin') as bool? ?? false);

  @override
  Color get color =>
      getColorFromPaletteWithStringAndBrightness('ykt') ??
      ColorService.defaultYktColor;

  @override
  YKTLoginPage getLoginPage({
    required ButtonStateContainer sc,
    required Function(ButtonStateContainer sc) onStateChange,
    required Function({bool toEnd}) onComplete,
    required bool onlyThis,
  }) =>
      YKTLoginPage(
          sc: sc,
          onStateChange: onStateChange,
          onComplete: onComplete,
          onlyThis: onlyThis);

  @override
  Future<void> init() async {
    _api = YKTApiService();
    await _api?.init();
  }

  /// 登录到一卡通
  ///
  /// 若登录成功，返回空的的状态容器；
  /// 否则，返回包含错误信息字符串的状态容器。
  @override
  Future<StatusContainer<dynamic>> login({
    String? username,
    String? password,
    int retries = 3,
    bool remember = true,
    StatusContainer? lastStatusContainer,
    String? manualCaptcha,
    bool useSOATGC = false,
  }) async {
    if (retries == 0) {
      return StatusContainer(
          Status.fail, lastStatusContainer?.value ?? '服务器错误，请稍后再试');
    }

    if (username == null || password == null) {
      username = YKTBox.get('username') as String?;
      password = YKTBox.get('password') as String?;
    }

    if (username == null || password == null) {
      return const StatusContainer(Status.fail, '内部参数错误');
    }

    final loginResult = _api != null
        ? await _api!.login(
            username: username,
            password: password,
            useSOATGC: useSOATGC,
          )
        : null;

    if (loginResult != null &&
        (loginResult.status == Status.manualCaptchaRequired ||
            loginResult.status == Status.captchaFailed)) {
      return loginResult;
    }

    if (loginResult == null || loginResult.status == Status.fail) {
      return await login(
        username: username,
        password: password,
        retries: retries - 1,
        remember: remember,
        lastStatusContainer: loginResult,
        manualCaptcha: manualCaptcha,
        useSOATGC: useSOATGC,
      );
    }

    final ticket = loginResult.value;
    await YKTBox.put('ticket', ticket);
    final tokenResult = await _api?.getAuthToken();
    if (tokenResult == null || tokenResult.status != Status.ok) {
      return tokenResult ?? const StatusContainer(Status.fail, '令牌获取失败');
    }

    final token = tokenResult.value as YKTAuthToken;

    await GlobalService.webViewCookieService?.deleteCookieSet('ykt');
    isLoginNotifier.value = true;

    await YKTBox.put('token', token);
    await YKTBox.put('isLogin', true);
    await YKTBox.put('username', username);
    await YKTBox.put('password', password);
    await YKTBox.put('remember', remember);

    final account = Account(account: username, password: password);
    await YKTBox.put('account', account);
    final accounts = savedAccounts.where((a) => a.equals(account)).isEmpty
        ? [account, ...savedAccounts]
        : savedAccounts;
    await YKTBox.put('accounts', accounts);

    await YKTBox.clearCache();

    return StatusContainer(Status.ok);
  }

  /// 退出登录
  @override
  Future<void> logout({required bool notify}) async {
    await _api?.logout();

    if (notify) {
      isLoginNotifier.value = false;
    }

    final keys = ['token', 'ticket', 'isLogin', 'account'];
    for (final key in keys) {
      await YKTBox.delete(key);
    }
    await YKTBox.clearCache();
    await _api?.deleteCookies();
    await GlobalService.webViewCookieService?.deleteCookieSet('ykt');
  }

  @override
  Future<StatusContainer<dynamic>> switchTo(Account account) async {
    await logout(notify: true);
    await YKTBox.clearCache();
    await _api?.deleteCookies();
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
    await YKTBox.put('accounts', savedAccounts);
    if (currentAccount?.equals(account) == true) {
      await logout(notify: true);
    }
  }

  /// 获取所有一卡通的卡片
  ///
  /// 成功时返回卡片列表，失败时返回错误信息字符串
  Future<StatusContainer<dynamic>> getCards() async {
    final result = await _api?.getCards();
    if (result == null || result.status != Status.ok) {
      return StatusContainer(
          result?.status ?? Status.fail, result?.value ?? '获取卡片失败');
    }

    List<YKTCard> cards = (result.value as List<dynamic>).cast();
    YKTBox.put('cards', cards);
    return StatusContainer(Status.ok, cards);
  }

  /// 根据卡账户和支付账户获取所有支付码
  ///
  /// 成功时返回一个 `List<String>`，否则返回错误信息字符串。
  Future<StatusContainer<dynamic>> getBarCodes({
    required String account,
    required String payAccount,
  }) async {
    return await _api?.getBarCodes(account: account, payAccount: payAccount) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 获取一卡通账单数据
  ///
  /// 成功时返回 `List<YKTBill>`，否则返回错误信息字符串
  Future<StatusContainer<dynamic>> getBills({
    required String account,
    required String payAccount,
    int page = 1,
    int pageSize = 10,
  }) async {
    return await _api?.getBills(
          account: account,
          payAccount: payAccount,
          page: page,
          pageSize: pageSize,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 获取指定时间段内的收支统计
  ///
  /// 成功时返回包含income和expenses的Map，否则返回错误信息字符串
  Future<StatusContainer<dynamic>> getStatistics({
    required String timeFrom,
    required String timeTo,
  }) async {
    return await _api?.getStatistics(
          timeFrom: timeFrom,
          timeTo: timeTo,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 挂失一卡通
  ///
  /// 成功时返回操作结果信息，失败时返回错误信息字符串
  Future<StatusContainer<dynamic>> lockCard(String cardNo) async {
    return await _api?.lockCard(cardNo: cardNo) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 解挂一卡通（保留接口，暂不实现）
  Future<StatusContainer<dynamic>> unlockCard(
      String cardNo, String password, String keyboardId) async {
    return await _api?.unlockCard(
          cardNo: cardNo,
          password: password,
          keyboardId: keyboardId,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 获取安全键盘
  ///
  /// 成功时返回安全键盘数据，失败时返回错误信息字符串
  Future<StatusContainer<dynamic>> getSecureKeyboard() async {
    return await _api?.getSecureKeyboard() ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 获取可缴费项目列表
  Future<StatusContainer<dynamic>> getPayApps({
    YKTAuthToken? token,
    int retries = 2,
  }) async {
    return await _api?.getPayApps() ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 获取电费缴费数据（校区、楼栋、楼层、房间等）
  Future<StatusContainer<dynamic>> getElectricityData({
    required String level,
    required String feeItemId,
    String? campus,
    String? building,
    String? floor,
  }) async {
    return await _api?.getElectricityData(
          level: level,
          feeItemId: feeItemId,
          campus: campus,
          building: building,
          floor: floor,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 获取用户信息
  Future<StatusContainer<dynamic>> getPaymentUserInfo({
    required String feeItemId,
  }) async {
    return await _api?.getPaymentUserInfo(
          feeItemId: feeItemId,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 获取电费数据的最终结果
  Future<StatusContainer<dynamic>> getElectricityFinalData({
    required String feeItemId,
    required String campus,
    required String building,
    required String floor,
    required String room,
  }) async {
    return await _api?.getElectricityFinalData(
          feeItemId: feeItemId,
          campus: campus,
          building: building,
          floor: floor,
          room: room,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 获取支付前的订单信息
  ///
  /// 成功时返回订单ID字符串，失败时返回错误信息
  Future<StatusContainer<dynamic>> getPaymentOrderInfo({
    required String feeItemId,
    required String amount,
    required Map<String, dynamic> roomData,
  }) async {
    return await _api?.getPaymentOrderInfo(
          feeItemId: feeItemId,
          amount: amount,
          roomData: roomData,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 获取详细的支付信息
  ///
  /// 成功时返回包含支付类型ID和支付类型代码的Map，失败时返回错误信息
  Future<StatusContainer<dynamic>> getDetailedPaymentInfo({
    required String feeItemId,
    required String orderId,
  }) async {
    return await _api?.getDetailedPaymentInfo(
          feeItemId: feeItemId,
          orderId: orderId,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 获取确认付款的密码映射和账户信息
  ///
  /// 成功时返回包含余额、账户类型和密码映射的Map，失败时返回错误信息
  Future<StatusContainer<dynamic>> getPaymentConfirmInfo({
    required String feeItemId,
    required String orderId,
    required String payTypeId,
    required String payType,
  }) async {
    return await _api?.getPaymentConfirmInfo(
          feeItemId: feeItemId,
          orderId: orderId,
          payTypeId: payTypeId,
          payType: payType,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 删除支付订单
  ///
  /// 成功时返回成功状态，失败时返回错误信息
  Future<StatusContainer<dynamic>> deletePaymentOrder({
    required String feeItemId,
    required String orderId,
  }) async {
    return await _api?.deletePaymentOrder(
          feeItemId: feeItemId,
          orderId: orderId,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }

  /// 执行最终支付操作
  ///
  /// 成功时返回支付结果，失败时返回错误信息
  Future<StatusContainer<dynamic>> executePayment({
    required String feeItemId,
    required String orderId,
    required String payTypeId,
    required String payType,
    required String password,
    required String keyboardId,
    required String accountType,
  }) async {
    return await _api?.executePayment(
          feeItemId: feeItemId,
          orderId: orderId,
          payTypeId: payTypeId,
          payType: payType,
          password: password,
          keyboardId: keyboardId,
          accountType: accountType,
        ) ??
        const StatusContainer(Status.fail, '本地服务未启动，请重启 APP');
  }
}
