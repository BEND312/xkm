import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/components/utils/refresh_icon.dart';
import 'package:swustmeow/components/ykt/ykt_bill_item.dart';
import 'package:swustmeow/components/ykt/ykt_card_info_panel.dart';
import 'package:swustmeow/components/ykt/ykt_empty_bills_view.dart';
import 'package:swustmeow/components/ykt/ykt_loading_more_indicator.dart';
import 'package:swustmeow/components/ykt/ykt_month_header.dart';
import 'package:swustmeow/entity/ykt/ykt_bill.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/entity/ykt/ykt_card_account_info.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/views/ykt/ykt_bill_detail_page.dart';

class YKTBillsPage extends StatefulWidget {
  final YKTCard card;
  final YKTCardAccountInfo account;

  const YKTBillsPage({
    super.key,
    required this.card,
    required this.account,
  });

  @override
  State<YKTBillsPage> createState() => _YKTBillsPageState();
}

class _YKTBillsPageState extends State<YKTBillsPage>
    with SingleTickerProviderStateMixin {
  static const int _pageSize = 10;

  final List<YKTBill> _bills = [];
  final Map<String, List<YKTBill>> _billsByMonth = {};
  final Map<String, Map<String, double>> _statisticsByMonth = {};

  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  bool _isRefreshing = false;
  late AnimationController _refreshAnimationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scrollController.addListener(_scrollListener);
    _loadBills(refresh: true);
  }

  @override
  void dispose() {
    _refreshAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoading && _hasMore) {
        _loadMoreBills();
      }
    }
  }

  Future<void> _loadBills({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _isRefreshing = true;
        _refreshAnimationController.repeat();
        _page = 1;
        _bills.clear();
        _billsByMonth.clear();
        _statisticsByMonth.clear();
      }
    });

    try {
      final info = widget.account;
      final [account, payAccount] = info.type.split('-');

      final result = await GlobalService.yktService?.getBills(
        account: account,
        payAccount: payAccount,
        page: _page,
        pageSize: _pageSize,
      );

      if (result == null || result.status != Status.ok) {
        showErrorToast(result?.value ?? '无法获取账单数据');
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _refreshAnimationController.stop();
          _refreshAnimationController.reset();
        });
        return;
      }

      List<YKTBill> newBills = (result.value as List<dynamic>).cast();

      // 添加新的账单到列表中
      _bills.addAll(newBills);

      // 按月分组账单
      _groupBillsByMonth();

      // 获取每月的统计数据
      await _loadMonthlyStatistics();

      setState(() {
        _hasMore = newBills.length >= _pageSize;
        _isLoading = false;
        _isRefreshing = false;
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
      });
      showErrorToast('加载失败：$e');
    }
  }

  void _groupBillsByMonth() {
    _billsByMonth.clear();

    for (var bill in _bills) {
      final date = bill.payTime;
      final monthKey = '${date.year}年${date.month}月';

      if (!_billsByMonth.containsKey(monthKey)) {
        _billsByMonth[monthKey] = [];
      }

      _billsByMonth[monthKey]!.add(bill);
    }

    // 对每个月内的账单按时间降序排序（最新的在前面）
    for (var monthKey in _billsByMonth.keys) {
      _billsByMonth[monthKey]!.sort((a, b) => b.payTime.compareTo(a.payTime));
    }
  }

  Future<void> _loadMonthlyStatistics() async {
    for (var monthKey in _billsByMonth.keys) {
      if (_statisticsByMonth.containsKey(monthKey)) continue;

      final parts = monthKey.split('年');
      final year = parts[0];
      final month = parts[1].replaceAll('月', '');

      // 计算月份的第一天和最后一天
      final firstDay = DateTime(int.parse(year), int.parse(month), 1);
      final lastDay = DateTime(int.parse(year), int.parse(month) + 1, 0);

      final timeFrom = DateFormat('yyyy-MM-dd').format(firstDay);
      final timeTo = DateFormat('yyyy-MM-dd').format(lastDay);

      final result = await GlobalService.yktService?.getStatistics(
        timeFrom: timeFrom,
        timeTo: timeTo,
      );

      if (result != null && result.status == Status.ok) {
        final stats = result.value as Map<String, dynamic>;
        _statisticsByMonth[monthKey] = {
          'income': stats['income'] as double,
          'expenses': stats['expenses'] as double,
        };
      } else {
        // 如果获取失败，使用默认值
        _statisticsByMonth[monthKey] = {
          'income': 0.0,
          'expenses': 0.0,
        };
      }
    }
  }

  Future<void> _loadMoreBills() async {
    _page++;
    await _loadBills();
  }

  void _onRefresh() {
    _loadBills(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      headerPad: false,
      header: BaseHeader(
        title: '账单明细',
        suffixIcons: [
          RefreshIcon(
            isRefreshing: _isRefreshing,
            onRefresh: _onRefresh,
          ),
        ],
      ),
      content: SafeArea(
        top: false,
        child: Column(
          children: [
            YKTCardInfoPanel(card: widget.card, account: widget.account),
            Expanded(
              child: _billsByMonth.isEmpty && !_isLoading
                  ? YKTEmptyBillsView()
                  : _buildGroupedBillsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedBillsList() {
    // 获取所有月份并排序
    final sortedMonths = _billsByMonth.keys.toList()
      ..sort((a, b) {
        // 降序排列，最新的月份在前
        final aParts = a.split('年');
        final bParts = b.split('年');
        final aYear = int.parse(aParts[0]);
        final bYear = int.parse(bParts[0]);
        if (aYear != bYear) return bYear.compareTo(aYear);

        final aMonth = int.parse(aParts[1].replaceAll('月', ''));
        final bMonth = int.parse(bParts[1].replaceAll('月', ''));
        return bMonth.compareTo(aMonth);
      });

    // 创建一个扁平化的项目列表，包含月份标题和账单项
    List<Widget> items = [];

    for (final month in sortedMonths) {
      final bills = _billsByMonth[month]!;
      final stats =
          _statisticsByMonth[month] ?? {'income': 0.0, 'expenses': 0.0};

      // 添加月份标题
      items.add(YKTMonthHeader(
        month: month,
        income: stats['income']!,
        expenses: stats['expenses']!,
      ));

      // 添加该月的所有账单项
      items.addAll(bills.map(
        (bill) => YKTBillItem(
          bill: bill,
          onTap: () {
            pushTo(context, '/ykt/bill_detail', YKTBillDetailPage(bill: bill));
          },
        ),
      ));
    }

    // 如果有更多内容可加载，添加加载指示器
    if (_hasMore) {
      items.add(YKTLoadingMoreIndicator());
    }

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: items,
    );
  }
}
