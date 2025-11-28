import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:forui/forui.dart';
import 'package:swustmeow/components/leave/leave_thing_information.dart';
import 'package:swustmeow/components/leave/leave_time_information.dart';
import 'package:swustmeow/components/leave/leave_go_back_information.dart';
import 'package:swustmeow/components/leave/leave_location_information.dart';
import 'package:swustmeow/components/leave/leave_out_information.dart';
import 'package:swustmeow/components/leave/leave_parent_information.dart';
import 'package:swustmeow/components/leave/leave_self_information.dart';
import 'package:swustmeow/components/utils/pop_receiver.dart';
import 'package:swustmeow/entity/soa/leave/daily_leave_action.dart';
import 'package:swustmeow/entity/soa/leave/daily_leave_options.dart';
import 'package:swustmeow/entity/soa/leave/leave_value_provider.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../components/utils/base_header.dart';
import '../../components/utils/base_page.dart';
import '../../components/utils/empty.dart';
import '../../data/m_theme.dart';
import '../../services/boxes/soa_box.dart';

class SOADailyLeavePage extends StatefulWidget {
  const SOADailyLeavePage({
    super.key,
    required this.action,
    this.template,
    this.leaveId,
    required this.onSaveDailyLeave,
    required this.onDeleteDailyLeave,
    required this.onRefresh,
  });

  final DailyLeaveAction action;
  final DailyLeaveOptions? template;
  final String? leaveId;
  final Function(DailyLeaveOptions options) onSaveDailyLeave;
  final Function(DailyLeaveOptions options) onDeleteDailyLeave;
  final Function() onRefresh;

  @override
  State<StatefulWidget> createState() => _SOADailyLeavePageState();
}

class _SOADailyLeavePageState extends State<SOADailyLeavePage> {
  late DailyLeaveAction _currentAction;
  WebUri? _url;
  DailyLeaveOptions? _options;
  bool _isSubmitting = false;
  bool _isLoading = true;
  InAppWebViewController? _webViewController;
  bool _isWebViewLoading = true;
  String? _extraValidatorMessage;
  final Map<String, dynamic> _template = {};
  bool _showRequiredOnly = false;

  @override
  void initState() {
    super.initState();
    _currentAction = widget.action;
    _load();
  }

  Future<void> _load() async {
    if (widget.leaveId != null && widget.template == null) {
      await _loadOptions();
    }

    if (widget.template != null) {
      _options = widget.template;
    }

    await _loadWebView();

    _refresh(() => _isLoading = false);
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  Future<void> _loadOptions() async {
    final id = widget.leaveId!;
    final result = await GlobalService.soaService?.getDailyLeaveInformation(id);
    if (result == null || result.status != Status.ok) {
      showErrorToast('无法加载请假信息');
      return;
    }
    final o = result.value! as DailyLeaveOptions;
    _refresh(() {
      _options = o;
      _isLoading = false;
    });
  }

  Future<void> _loadWebView() async {
    final service = GlobalService.soaService;
    if (service == null) return;

    final api = service.api;
    if (api == null) return;

    final tgcResult = await service.checkLogin();
    if (tgcResult.status != Status.ok) return; // TODO 处理 notAuthorized 自动登录

    final xscResult = await api.loginToXSC(tgcResult.value!);
    if (xscResult.status != Status.ok) return; // TODO 处理 notAuthorized 自动登录

    final base =
        'http://xsc.swust.edu.cn/Sys/SystemForm/Leave/StuAllLeaveManage_Edit.aspx';

    final cookies = await api.getCookies(Uri.parse(base));

    // Map<String, String> processEncodedEditParams() {
    //   // 以下算法来自学工系统 JavaScript
    //   final s1 = randomInt(9);
    //   final salt1 = md5.convert(utf8.encode('$s1')).toString().toLowerCase();
    //   final salt2 = randomBetween(1, 9999).toString().padLeft(4, '0');
    //   return {
    //     'Status': 'RWRpdA;;', // == (base64('Edit') + ';;')  但不知为何编码后有尾缀 `==`
    //     'Id': '${base64.encode(utf8.encode(widget.leaveId ?? ''))}$salt1$salt2'
    //   };
    // }

    final cookieManager = CookieManager.instance();

    final uri = Uri.http(
      'xsc.swust.edu.cn',
      '/Sys/SystemForm/Leave/StuAllLeaveManage_Edit.aspx',
      switch (widget.action) {
        DailyLeaveAction.add => {'Status': 'Add'},
        DailyLeaveAction.edit || DailyLeaveAction.delete => {
            'Status': 'Edit',
            'Id': widget.leaveId ?? ''
          }
        // processEncodedEditParams()
      },
    );
    final url = WebUri.uri(uri);

    for (final cookie in cookies) {
      await cookieManager.setCookie(
          url: url, name: cookie.name, value: cookie.value);
    }

    _refresh(() => _url = url);
  }

  void _stop() {
    _webViewController?.dispose();
    _webViewController = null;
  }

  Future<void> _setFieldValue(String id, String value) async {
    if (_webViewController == null) return;
    await _runJs('''
      var field = document.querySelector('#$id');
      field.value = '$value';
    ''');
  }

  Future<void> _setSelectValue(String id, String value) async {
    if (_webViewController == null) return;
    await _runJs('''
      var select = document.querySelector('#$id');
      select.value = '$value';
      select.onchange();
    ''');
  }

  Future<void> _setTableCheckValue(String id, String value) async {
    if (_webViewController == null) return;
    await _runJs('''
      var table = document.querySelector('#$id');
      var inputs = Array.from(table.querySelectorAll('tbody > tr > td > input'));
      var option = inputs.filter((c) => c.value === '$value')[0];
      var checked = inputs.filter((c) => c.getAttribute('checked' === 'checked'));
      
      if (checked.length !== 0) {
        for (var checkedElement of checked) {
          checkedElement.removeAttribute('checked');
        }
      }
      
      option.setAttribute('checked', 'checked');
    ''');
  }

  Future<void> _setSpanCheckValue(String id, String value) async {
    await _runJs('''
      var span = document.querySelector('#$id');
      var inputs = Array.from(span.querySelectorAll('input'));
      var option = inputs.filter((c) => c.value === '$value')[0];
      option.click();
    ''');
  }

  Future<void> _runJs(String source) async {
    if (_webViewController == null) return;
    await _webViewController!.evaluateJavascript(source: source);
  }

  void _setValidatorMessage(String? message) {
    _refresh(() => _extraValidatorMessage = message);
  }

  void _setTemplateValue(String key, dynamic value) {
    _template[key] = value;
  }

  Future<void> _saveAsTemplate() async {
    if (_webViewController == null) return;
    final options = DailyLeaveOptions.fromJson(_template);
    await SOABox.put('leaveTemplate', options);
    showSuccessToast('保存成功！');
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopReceiver(
      onPop: widget.onRefresh,
      child: Stack(
        children: [
          Opacity(
            opacity: 0,
            child: InAppWebView(
              key: ValueKey(_url),
              initialUrlRequest: URLRequest(url: _url),
              initialSettings: InAppWebViewSettings(
                userAgent:
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36 Edg/132.0.0.0',
              ),
              onLoadStart: (controller, _) => _webViewController = controller,
              onLoadStop: (controller, _) =>
                  _refresh(() => _isWebViewLoading = false),
              onJsAlert: (controller, request) async {
                await _onAlert(request);
                return JsAlertResponse(handledByClient: true);
              },
              onJsConfirm: (controller, request) async {
                final title = request.message;
                bool? r = await showAdaptiveDialog(
                  context: context,
                  builder: (context) => FDialog(
                    direction: Axis.horizontal,
                    title: Text(title ?? '确认操作？'),
                    body: SizedBox(height: 12.0),
                    actions: [
                      FButton(
                        style: FButtonStyle.outline,
                        onPress: () {
                          Navigator.of(context).pop(false);
                          _refresh(() => _isSubmitting = false);
                        },
                        label: Text('取消'),
                      ),
                      FButton(
                        onPress: () => Navigator.of(context).pop(true),
                        label: Text('确定'),
                      ),
                    ],
                  ),
                );
                return JsConfirmResponse(
                  handledByClient: true,
                  action: r == true
                      ? JsConfirmResponseAction.CONFIRM
                      : JsConfirmResponseAction.CANCEL,
                );
              },
              onCloseWindow: (_) => _stop(),
            ),
          ),
          Opacity(
            opacity: 1,
            child: BasePage(
              headerPad: false,
              header: BaseHeader(
                title: switch (widget.action) {
                  DailyLeaveAction.add => '新增日常请假',
                  _ => '编辑日常请假'
                },
              ),
              content: _isLoading || _isWebViewLoading
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: MTheme.primary2,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '加载中...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : SingleChildScrollView(
                padding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: _buildForm(),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 32,
            child: FloatingActionButton(
              heroTag: null,
              backgroundColor: _showRequiredOnly ? Colors.orange : Colors.teal,
              onPressed: () =>
                  _refresh(() => _showRequiredOnly = !_showRequiredOnly),
              child: Icon(
                _showRequiredOnly
                    ? FontAwesomeIcons.eyeSlash
                    : FontAwesomeIcons.eye,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final ts = TextStyle(
      fontSize: 16,
      color: _isSubmitting ? Colors.grey : context.theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
    final ts2 = TextStyle(
      fontSize: 12,
      color: Colors.grey,
      fontWeight: FontWeight.w500,
    );

    final provider = LeaveValueProvider(
      leaveId: widget.leaveId,
      isLoading: _isLoading || _isWebViewLoading,
      options: _options,
      ts: ts,
      ts2: ts2,
      showRequiredOnly: _showRequiredOnly,
      buildLineCalendar: _buildLineCalendar,
      buildTimeSelector: _buildTimeSelector,
      runJs: _runJs,
      setFieldValue: _setFieldValue,
      setSelectValue: _setSelectValue,
      setTableCheckValue: _setTableCheckValue,
      setSpanCheckValue: _setSpanCheckValue,
      setValidatorMessage: _setValidatorMessage,
      setTemplateValue: _setTemplateValue,
    );

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_extraValidatorMessage != null)
            Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.circleExclamation,
                    color: Colors.red,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _extraValidatorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!_showRequiredOnly) ...[
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.circleInfo,
                  size: 16,
                  color: MTheme.primary2,
                ),
                SizedBox(width: 8),
                Text(
                  '基本信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LeaveSelfInformation(provider: provider),
            SizedBox(height: 24),
          ],
          Row(
            children: [
              Icon(
                FontAwesomeIcons.clock,
                size: 16,
                color: MTheme.primary2,
              ),
              SizedBox(width: 8),
              Text(
                '请假时间',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LeaveTimeInformation(provider: provider),
          SizedBox(height: 24),
          Row(
            children: [
              Icon(
                FontAwesomeIcons.bus,
                size: 16,
                color: MTheme.primary2,
              ),
              SizedBox(width: 8),
              Text(
                '往返信息',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LeaveGoBackInformation(provider: provider),
          SizedBox(height: 24),
          Row(
            children: [
              Icon(
                FontAwesomeIcons.locationDot,
                size: 16,
                color: MTheme.primary2,
              ),
              SizedBox(width: 8),
              Text(
                '外出信息',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LeaveLocationInformation(provider: provider),
          SizedBox(height: 24),
          Row(
            children: [
              Icon(
                FontAwesomeIcons.addressBook,
                size: 16,
                color: MTheme.primary2,
              ),
              SizedBox(width: 8),
              Text(
                '外出联系人',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LeaveOutInformation(provider: provider),
          SizedBox(height: 24),
          if (!_showRequiredOnly) ...[
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.phone,
                  size: 16,
                  color: MTheme.primary2,
                ),
                SizedBox(width: 8),
                Text(
                  '联系信息',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            LeaveParentInformation(provider: provider),
            SizedBox(height: 24),
          ],
          Row(
            children: [
              Icon(
                FontAwesomeIcons.fileLines,
                size: 16,
                color: MTheme.primary2,
              ),
              SizedBox(width: 8),
              Text(
                '请假事由',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          LeaveThingInformation(provider: provider),
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FButton(
                  onPress: _isSubmitting ? null : _submit,
                  style: FButtonStyle.primary,
                  prefix: Icon(
                    FontAwesomeIcons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    switch (_currentAction) {
                      DailyLeaveAction.add => '提交请假申请',
                      DailyLeaveAction.edit => '修改请假申请',
                      DailyLeaveAction.delete => '撤销请假申请'
                    },
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
          if (widget.action != DailyLeaveAction.add) ...[
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: FButton(
                    onPress: () async {
                      if (_isSubmitting) return;
                      _currentAction = DailyLeaveAction.delete;
                      await _submit();
                    },
                    style: FButtonStyle.destructive,
                    prefix: Icon(
                      FontAwesomeIcons.trashCan,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      '删除请假',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_template.isNotEmpty) ...[
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: FButton(
                    onPress: _saveAsTemplate,
                    style: FButtonStyle.outline,
                    prefix: Icon(FontAwesomeIcons.floppyDisk, size: 16),
                    label: Text(
                      '存为模板',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 64),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_webViewController == null) return;

    if (_extraValidatorMessage != null) {
      showErrorToast(_extraValidatorMessage!);
      return;
    }

    _refresh(() => _isSubmitting = true);

    switch (_currentAction) {
      case DailyLeaveAction.add:
      case DailyLeaveAction.edit:
        await _runJs('''
          var saveButton = document.querySelector('#Save');
          saveButton.click();
        ''');
        return;
      case DailyLeaveAction.delete:
        await _runJs('''
          var deleteButton = document.querySelector('#Del');
          deleteButton.click();
        ''');
        return;
    }
  }

  Future<void> _onAlert(JsAlertRequest request) async {
    final message = request.message;
    if (message == null || message.isEmpty) return;

    if (message.contains('成功')) {
      showSuccessToast(switch (_currentAction) {
        DailyLeaveAction.add => '请假成功',
        DailyLeaveAction.edit => '修改请假成功',
        DailyLeaveAction.delete => '撤销请假成功'
      });

      switch (_currentAction) {
        case DailyLeaveAction.add:
        case DailyLeaveAction.edit:
          widget.onSaveDailyLeave(_options!);
          break;
        case DailyLeaveAction.delete:
          widget.onDeleteDailyLeave(_options!);
          break;
      }
    } else {
      showErrorToast(message);
    }

    _refresh(() => _isSubmitting = false);
    // Navigator.of(context).pop();
  }

  Widget _buildLineCalendar(FCalendarController<DateTime?>? controller,
      {DateTime? start}) {
    final now = DateTime.now();
    if (controller == null) return const Empty();
    return SizedBox(
      height: 50,
      child: FLineCalendar(
        controller: controller,
        initialDateAlignment: AlignmentDirectional.center,
        cacheExtent: 100,
        today: start ?? now,
        start: start ?? now,
        end: DateTime(now.year, now.month, now.day + 999 - 1),
        builder: _lineCalendarItemBuilder,
      ),
    );
  }

  Widget _buildTimeSelector(int value, void Function(int) onChange) {
    return SizedBox(
      height: 50,
      child: NumberPicker(
        minValue: 0,
        maxValue: 23,
        itemWidth: 50,
        itemHeight: 20,
        itemCount: 3,
        zeroPad: true,
        textMapper: (v) => '$v时',
        textStyle:
            TextStyle(fontSize: 12, color: Colors.grey.withValues(alpha: 0.5)),
        selectedTextStyle: TextStyle(fontSize: 14),
        value: value,
        onChanged: onChange,
      ),
    );
  }

  Widget _lineCalendarItemBuilder(
      BuildContext context, FLineCalendarItemData state, Widget? child) {
    final localizations = FLocalizations.of(context) ?? FDefaultLocalizations();
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: state.focused
                ? state.itemStyle.focusedDecoration
                : state.itemStyle.decoration,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DefaultTextStyle.merge(
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style:
                        state.itemStyle.weekdayTextStyle.copyWith(fontSize: 10),
                    child: Text(localizations.abbreviatedMonth(state.date)),
                  ),
                  SizedBox(height: state.style.itemContentSpacing),
                  DefaultTextStyle.merge(
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style: state.itemStyle.dateTextStyle.copyWith(fontSize: 14),
                    child: Text(localizations.day(state.date)),
                  ),
                  SizedBox(height: state.style.itemContentSpacing),
                  DefaultTextStyle.merge(
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                    ),
                    style:
                        state.itemStyle.weekdayTextStyle.copyWith(fontSize: 8),
                    child: Text(
                        localizations.shortWeekDays[state.date.weekday % 7]),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (state.today)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              height: 4,
              width: 4,
              decoration: BoxDecoration(
                color: state.itemStyle.todayIndicatorColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
