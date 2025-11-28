import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/entity/ykt/ykt_pay_app.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/views/ykt/pay/ykt_electricity_pay_page.dart';
import 'package:swustmeow/views/ykt/pay/ykt_simple_pay_page.dart';

class YKTUtilityPaymentPage extends StatefulWidget {
  final List<YKTCard> cards;

  const YKTUtilityPaymentPage({
    super.key,
    required this.cards,
  });

  @override
  State<YKTUtilityPaymentPage> createState() => _YKTUtilityPaymentPageState();
}

class _YKTUtilityPaymentPageState extends State<YKTUtilityPaymentPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<YKTPayApp> _payApps = [];
  late AnimationController _refreshAnimationController;

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadPayApps();
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPayApps() async {
    setState(() {
      _isLoading = true;
      _isRefreshing = true;
      _refreshAnimationController.repeat();
    });

    try {
      if (GlobalService.yktService == null) {
        showErrorToast('本地服务未启动，请重启 APP');
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _refreshAnimationController.stop();
          _refreshAnimationController.reset();
        });
        return;
      }

      final appsResult = await GlobalService.yktService!.getPayApps();
      if (appsResult.status != Status.ok) {
        showErrorToast(appsResult.value ?? '未知错误');
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _refreshAnimationController.stop();
          _refreshAnimationController.reset();
        });
        return;
      }

      if (appsResult.value is! List) {
        showErrorToast('获取缴费应用失败：数据格式错误');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      List<YKTPayApp> apps = (appsResult.value as List<dynamic>).cast<YKTPayApp>();
      setState(() {
        _payApps = apps;
        _isLoading = false;
        _isRefreshing = false;
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
      });
    } catch (e) {
      showErrorToast('加载失败：$e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
      });
    }
  }

  void _onRefresh() {
    _loadPayApps();
  }

  // 根据应用名称获取图标
  IconData _getIconForApp(String appName) {
    switch (appName) {
      case '电费':
        return FontAwesomeIcons.bolt;
      case '水费':
        return FontAwesomeIcons.droplet;
      case '维修赔偿费':
        return FontAwesomeIcons.wrench;
      default:
        return FontAwesomeIcons.moneyBill;
    }
  }

  // 根据应用名称获取颜色
  Color _getColorForApp(String appName) {
    switch (appName) {
      case '电费':
        return Colors.orange;
      case '水费':
        return Colors.blue;
      case '维修赔偿费':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  // 处理特定支付应用
  void _handlePayApp(YKTPayApp app) {
    // 电费缴费特殊处理
    if (app.name == '电费') {
      pushTo(
        context,
        '/ykt/payments/electricity',
        YKTElectricityPayPage(
          cards: widget.cards,
          payApp: app,
        ),
      );
      return;
    }

    // 其他应用
    pushTo(
      context,
      '/ykt/payments/${app.feeItemId}',
      YKTSimplePayPage(
        cards: widget.cards,
        payApp: app,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(
        title: '生活缴费',
        suffixIcons: [
          RefreshIcon(
            isRefreshing: _isRefreshing,
            onRefresh: _onRefresh,
          ),
        ],
      ),
      content: SafeArea(
        top: false,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: MTheme.primary2,
                    ),
                    SizedBox(height: 16),
                    Text('正在加载缴费应用...'),
                  ],
                ),
              )
            : _payApps.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          FontAwesomeIcons.fileCircleExclamation,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          '暂无可用的缴费应用',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '请稍后再试或联系管理员',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: _buildPayAppsList(),
                  ),
      ),
    );
  }

  Widget _buildPayAppsList() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _payApps.length,
      itemBuilder: (context, index) {
        final app = _payApps[index];
        final iconData = _getIconForApp(app.name);
        final iconColor = _getColorForApp(app.name);

        return GestureDetector(
          onTap: () => _handlePayApp(app),
          child: Container(
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(MTheme.radius),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // 背景大图标
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(
                      iconData,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
                // 内容
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              iconData,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            app.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        '点击立即缴费',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
