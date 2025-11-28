import 'dart:async';
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/entity/ykt/ykt_card_account_info.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/components/ykt/ykt_card_info_panel.dart';

class YKTPaymentPage extends StatefulWidget {
  final YKTCard card;
  final YKTCardAccountInfo account;

  const YKTPaymentPage({
    super.key,
    required this.card,
    required this.account,
  });

  @override
  State<YKTPaymentPage> createState() => _YKTPaymentPageState();
}

class _YKTPaymentPageState extends State<YKTPaymentPage>
    with SingleTickerProviderStateMixin {
  static const _refreshInterval = 10;
  int _remainingSeconds = _refreshInterval;
  Timer? _timer;
  String _barcode = 'this is an easter egg';
  late AnimationController _refreshAnimationController;
  bool _isRefreshing = false;
  List<String> _barcodes = [];
  int? _currentBarcodeIndex;

  @override
  void initState() {
    super.initState();
    ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isRefreshing = true;
      _refreshAnimationController.repeat();
    });

    await _getBarcodes();
    _onRefresh();
    _startTimer();
  }

  Future<void> _getBarcodes() async {
    final info = widget.account;
    final [account, payAccount] = info.type.split('-');
    final barcodesResult = await GlobalService.yktService
        ?.getBarCodes(account: account, payAccount: payAccount);
    if (barcodesResult == null || barcodesResult.status != Status.ok) {
      showErrorToast(barcodesResult?.value ?? '无法获取支付码');
      return;
    }

    if (barcodesResult.value is! List) {
      showErrorToast('获取条码失败：数据格式错误');
      return;
    }

    List<String> barcodes = (barcodesResult.value as List<dynamic>).cast<String>();
    setState(() {
      _barcodes = barcodes;
    });
  }

  void _generatePayCode() {
    if (_currentBarcodeIndex == _barcodes.length ||
        _currentBarcodeIndex == null) {
      _currentBarcodeIndex = 0;
    }

    setState(() {
      _barcode = _barcodes[_currentBarcodeIndex!];
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _remainingSeconds = _refreshInterval;
          _onRefresh();
        }
      });
    });
  }

  void _onRefresh() async {
    setState(() {
      _remainingSeconds = _refreshInterval;
      if (_currentBarcodeIndex == null) {
        _currentBarcodeIndex = 0;
      } else {
        _currentBarcodeIndex = _currentBarcodeIndex! + 1;
      }
      _generatePayCode();
      _isRefreshing = false;
      _refreshAnimationController.stop();
      _refreshAnimationController.reset();
    });
  }

  @override
  void dispose() {
    ScreenBrightness.instance.resetApplicationScreenBrightness();
    _timer?.cancel();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(
        title: '付款码',
        suffixIcons: [
          RefreshIcon(
            isRefreshing: _isRefreshing,
            onRefresh: _onRefresh,
          ),
        ],
      ),
      content: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              YKTCardInfoPanel(
                card: widget.card,
                account: widget.account,
              ),
              _buildPayCode(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayCode() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MTheme.radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: Offset(0, 2),
            )
          ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: BarcodeWidget(
                    data: _barcode,
                    barcode: Barcode.code128(),
                    drawText: !_isRefreshing,
                    width: double.infinity,
                    height: 100,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  width: 180,
                  child: BarcodeWidget(
                    data: _barcode,
                    barcode: Barcode.qrCode(),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(MTheme.radius),
                ),
                child: Text(
                  '$_remainingSeconds秒后刷新',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        '请将付款码对准扫码设备',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }
}
