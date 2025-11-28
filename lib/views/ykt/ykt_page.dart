import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/components/utils/base_page.dart';
import 'package:swustmeow/components/utils/pop_receiver.dart';
import 'package:swustmeow/components/ykt/ykt_function_item.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/entity/ykt/ykt_card.dart';
import 'package:swustmeow/services/boxes/ykt_box.dart';
import 'package:swustmeow/services/global_service.dart';
import 'package:swustmeow/utils/common.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:swustmeow/utils/router.dart';
import 'package:swustmeow/utils/status.dart';
import 'package:swustmeow/views/ykt/ykt_bills_page.dart';

import '../../entity/ykt/ykt_card_account_info.dart';
import 'package:swustmeow/components/ykt/ykt_flippable_card.dart';
import 'package:swustmeow/components/ykt/ykt_account_tabs.dart';
import 'package:swustmeow/views/ykt/ykt_payment_page.dart';
import 'package:swustmeow/views/ykt/ykt_loss_report_page.dart';
import 'package:swustmeow/views/ykt/ykt_utility_payment_page.dart';

class YKTPage extends StatefulWidget {
  const YKTPage({super.key});

  @override
  State<YKTPage> createState() => _YKTPageState();
}

class _YKTPageState extends State<YKTPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<YKTCard> _cards = [];
  int _currentCardIndex = 0;
  int _currentAccountIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cached = YKTBox.get('cards') as List<dynamic>?;
    if (cached != null) {
      _refresh(() {
        _isLoading = false;
        _cards = cached.cast();
      });
    }

    if (GlobalService.yktService == null) {
      showErrorToast('本地服务未启动，请重启 APP');
      return;
    }

    final cardsResult = await GlobalService.yktService!.getCards();
    if (cardsResult.status != Status.ok) {
      showErrorToast(cardsResult.value ?? '未知错误');
      return;
    }

    List<YKTCard> cards = (cardsResult.value as List<dynamic>).cast();
    _refresh(() {
      _isLoading = false;
      _cards = cards;
    });
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BasePage(
        headerPad: false,
        header: BaseHeader(title: '一卡通'),
        content: !_isLoading
            ? SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardsSection(),
              SizedBox(height: 8),
              _buildAccountSection(),
              SizedBox(height: 16),
              _buildFunctionsSection(),
            ],
          ),
        )
            : Center(
          child: CircularProgressIndicator(
            color: MTheme.primary2,
          ),
        ),
      ),
    );
  }

  Widget _buildCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 20, top: 20),
          child: Text(
            '我的卡包',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: Swiper(
            itemBuilder: (context, index) {
              YKTCard card = _cards[index];
              YKTCardAccountInfo? accountInfo = card.accountInfos.isNotEmpty &&
                      _currentAccountIndex < card.accountInfos.length
                  ? card.accountInfos[_currentAccountIndex]
                  : null;

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: YKTFlippableCard(
                  card: card,
                  accountInfo: accountInfo,
                ),
              );
            },
            itemCount: _cards.length,
            viewportFraction: 0.9,
            scale: 1,
            loop: false,
            onIndexChanged: (index) {
              setState(() {
                _currentCardIndex = index;
                // 重置账户索引，避免越界
                _currentAccountIndex = 0;
              });
            },
            pagination: SwiperPagination(
              margin: EdgeInsets.only(top: 0),
              builder: DotSwiperPaginationBuilder(
                activeColor: Color(_cards[_currentCardIndex].color),
                color: Colors.grey.withAlpha(77),
                size: 6.0,
                activeSize: 6.0,
              ),
            ),
            duration: 300,
            curve: Curves.easeOutCubic,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    if (_cards.isEmpty) return SizedBox();

    return YKTAccountTabs(
      card: _cards[_currentCardIndex],
      currentAccountIndex: _currentAccountIndex,
      onAccountChanged: (index) {
        setState(() {
          _currentAccountIndex = index;
        });
      },
    );
  }

  Widget _buildFunctionsSection() {
    YKTCard? currentCard = _cards.isNotEmpty ? _cards[_currentCardIndex] : null;
    YKTCardAccountInfo? currentAccount = (currentCard != null &&
            currentCard.accountInfos.isNotEmpty &&
            _currentAccountIndex < currentCard.accountInfos.length)
        ? currentCard.accountInfos[_currentAccountIndex]
        : null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '功能',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: YKTFunctionItem(
                  icon: FontAwesomeIcons.moneyBillWave,
                  title: '付款',
                  description: '快速出示付款码',
                  color: Color(0xFF4CAF50),
                  onTap: () {
                    _handlePayment(currentCard, currentAccount);
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: YKTFunctionItem(
                  icon: FontAwesomeIcons.fileInvoiceDollar,
                  title: '账单',
                  description: '查看消费记录',
                  color: Color(0xFF2196F3),
                  onTap: () {
                    _viewBills(currentCard, currentAccount);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: YKTFunctionItem(
                  icon: currentCard?.isLocked == true
                      ? FontAwesomeIcons.lockOpen
                      : FontAwesomeIcons.lock,
                  title: currentCard?.isLocked == true ? '解挂' : '挂失',
                  description:
                      currentCard?.isLocked == true ? '恢复卡片使用' : '临时冻结卡片',
                  color: Color(0xFF502AF7),
                  onTap: () {
                    _handleLossReport(currentCard, currentAccount);
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: YKTFunctionItem(
                  icon: FontAwesomeIcons.bolt,
                  title: '缴费',
                  description: '电费水费等生活缴费',
                  color: Color(0xFFFF9800),
                  onTap: () {
                    _handleUtilityPayment();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  // 处理付款操作
  void _handlePayment(YKTCard? card, YKTCardAccountInfo? account) {
    if (card == null || account == null) {
      showErrorToast('无法获取卡片或账户信息');
      return;
    }

    pushTo(
        context, '/ykt/payment', YKTPaymentPage(card: card, account: account));
  }

  // 查看账单
  void _viewBills(YKTCard? card, YKTCardAccountInfo? account) {
    if (card == null || account == null) {
      showErrorToast('无法获取卡片或账户信息');
      return;
    }

    pushTo(context, '/ykt/bills', YKTBillsPage(card: card, account: account));
  }

  // 处理挂失/解挂
  void _handleLossReport(YKTCard? card, YKTCardAccountInfo? account) {
    if (card == null || account == null) {
      showErrorToast('无法获取卡片或账户信息');
      return;
    }

    pushTo(
      context,
      '/ykt/loss_report',
      YKTLossReportPage(
        card: card,
        account: account,
        onRefresh: _loadCards,
      ),
    );
  }

  // 处理生活缴费
  void _handleUtilityPayment() {
    pushTo(
      context,
      '/ykt/util_payments',
      PopReceiver(
        onPop: _loadCards,
        child: YKTUtilityPaymentPage(cards: _cards),
      ),
    );
  }
}
