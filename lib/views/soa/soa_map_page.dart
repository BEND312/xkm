import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:swustmeow/components/base_webview.dart';
import 'package:swustmeow/components/utils/base_header.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/services/permission_service.dart';
import 'package:swustmeow/utils/common.dart';

import '../../components/header_selector.dart';
import '../../components/utils/base_page.dart';

class SOAMapPage extends StatefulWidget {
  const SOAMapPage({super.key});

  @override
  State<StatefulWidget> createState() => _SOAMapPageState();
}

class _SOAMapPageState extends State<SOAMapPage> {
  InAppWebViewController? _controller;
  final _checkInterval = Duration(milliseconds: 100);
  bool _isLoading = true;
  bool _disposed = false;
  String _currentCampus = '青义校区';

  static const _url = 'https://gis.swust.edu.cn/#/home?campus=78924';
  final _operations =
      '''document.querySelector('body > app-root > div.layer-operations')''';
  final _header =
      '''document.querySelector('body > app-root > app-home > app-header > div')''';
  final _searchPanel =
      '''document.querySelector('body > app-root > app-home > app-search > div.search-panel')''';
  final _searchResult =
      '''document.querySelector('body > app-root > app-home > app-search > div.search-result')''';
  final _campusListSelector =
      '''document.querySelectorAll('body > app-root > app-home > div.select-campus-box > div > div')''';

  bool _operationsFound = false;
  bool _headerFound = false;
  bool _searchPanelFound = false;
  bool _searchResultFound = false;
  List<String>? _campusList;

  late final List<Future<bool> Function()> _ops;

  @override
  void initState() {
    super.initState();
    _ops = [
      _changeOperationsPosition,
      _removeHeader,
      _changeSearchPosition,
      _changeSearchResultSize,
      _getCampusList
    ];
    _requestPermission();
  }

  @override
  void dispose() {
    if (_controller != null && !_disposed) {
      _controller?.dispose();
      _controller = null;
    }
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final status =
        await PermissionService.requestPermission(Permission.location);
    if (status != PermissionStatus.granted && !Platform.isIOS) {
      showErrorToast('无定位权限或被限制，地图部分功能可能不可用');
    }
  }

  void _refresh([Function()? fn]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn ?? () {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final campusList = _campusList ?? [_currentCampus];

    return BasePage(
      headerPad: false,
      header: BaseHeader(
        title: HeaderSelector<String>(
          enabled: !_isLoading,
          initialValue: _currentCampus,
          onSelect: (value) async {
            final flag = await _onChangeCampus(value);
            if (!flag) return;
            _refresh(() => _currentCampus = value);
          },
          count: campusList.length,
          titleBuilder: (context, index) => Align(
            alignment: Alignment.centerRight,
            child: Column(
              children: [
                Text(
                  '校园地图',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: MTheme.backgroundText,
                  ),
                ),
                AutoSizeText(
                  _currentCampus,
                  maxLines: 1,
                  maxFontSize: 12,
                  minFontSize: 8,
                  style: TextStyle(color: MTheme.backgroundText),
                )
              ],
            ),
          ),
          tileValueBuilder: (context, index) => campusList[index],
          tileTextBuilder: (context, index) => Text(
            campusList[index],
            style: TextStyle(fontSize: 14),
          ),
          fallbackTitle: Text('未知校区'),
        ),
        suffixIcons: [
          IconButton(
            onPressed: () async {
              if (_isLoading) return;
              await _onSearch();
            },
            icon: FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              color: MTheme.backgroundText,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () async {
              if (_isLoading || _disposed) return;
              _refresh(() {
                _operationsFound = false;
                _headerFound = false;
                _searchPanelFound = false;
                _searchResultFound = false;
              });
              await _controller?.reload();
            },
            icon: FaIcon(
              FontAwesomeIcons.rotateRight,
              color: MTheme.backgroundText,
              size: 20,
            ),
          )
        ],
      ),
      content: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(MTheme.radius),
          topRight: Radius.circular(MTheme.radius),
        ),
        child: BaseWebView(
          url: _url,
          onLoadStart: (controller, _) async {
            _controller = controller;
            for (final op in _ops) {
              await Future.doWhile(op);
            }
          },
          onLoadStop: (_, __) => _refresh(() => _isLoading = false),
          onDispose: () => _disposed = true,
        ),
      ),
    );
  }

  Future<void> _onSearch() async {
    if (!_searchPanelFound || _controller == null || _disposed) return;

    await _controller!.evaluateJavascript(source: '''
      var search = $_searchPanel;
      var ops = $_operations;
      var tag = 'active';
      var active = search.classList.contains(tag);
      if (active) {
        ops.style.top = '0.3rem';
        search.classList.remove(tag);
      } else {
        ops.style.top = '1.3rem';
        search.classList.add(tag);
      }
    ''');
  }

  Future<bool> _changeOperationsPosition() async {
    if (_controller == null) return true;
    if (_operationsFound) return false;
    await Future.delayed(_checkInterval);

    if (_disposed) return false;
    bool result =
        await _controller!.evaluateJavascript(source: '$_operations !== null');
    if (result) {
      _operationsFound = true;
      await _controller!
          .evaluateJavascript(source: '''$_operations.style.top = '0.3rem';''');
      return false;
    }
    return true;
  }

  Future<bool> _removeHeader() async {
    if (_controller == null) return true;
    if (_headerFound) return false;
    await Future.delayed(_checkInterval);

    if (_disposed) return false;
    bool result =
        await _controller!.evaluateJavascript(source: '$_header !== null');
    if (result) {
      _headerFound = true;
      await _controller!
          .evaluateJavascript(source: '''$_header.style.display = 'none';''');
      return false;
    }
    return true;
  }

  Future<bool> _changeSearchPosition() async {
    if (_controller == null) return true;
    if (_searchPanelFound) return false;
    await Future.delayed(_checkInterval);

    if (_disposed) return false;
    bool result =
        await _controller!.evaluateJavascript(source: '$_searchPanel !== null');
    if (result) {
      _searchPanelFound = true;
      await _controller!.evaluateJavascript(source: '''
        var search = $_searchPanel;
        
        var box = search.querySelector('div.search-box');
        box.style.paddingLeft = '0px';
        var icon = box.querySelector('div.search-return');
        icon.style.display = 'none';
        
        var recommend = search.querySelector('div.search-recommend');
        recommend.style.boxShadow = '0 0px 0px white';
      ''');
      return false;
    }
    return true;
  }

  Future<bool> _changeSearchResultSize() async {
    if (_controller == null) return true;
    if (_searchResultFound) return false;
    await Future.delayed(_checkInterval);

    if (_disposed) return false;
    bool result = await _controller!
        .evaluateJavascript(source: '$_searchResult !== null');
    if (result) {
      _searchResultFound = true;
      await _controller!.evaluateJavascript(source: '''
        var result = $_searchResult;
        result.style.minHeight = '2.4rem';
        
        var total = result.querySelector('div.total-search-result');
        total.style.height = '1.2rem';
        total.style.alignContent = 'center';
      ''');
      return false;
    }
    return true;
  }

  Future<bool> _getCampusList() async {
    if (_controller == null) return true;
    if (_campusList != null) return false;
    await Future.delayed(_checkInterval);

    if (_disposed) return false;
    bool result = await _controller!
        .evaluateJavascript(source: '$_campusListSelector !== null');
    if (result) {
      List<dynamic> list = await _controller!.evaluateJavascript(source: '''
        var list = Array.from($_campusListSelector);
        list.map((element) => element.innerText);
      ''');
      _refresh(() => _campusList = list.cast());
      return false;
    }
    return true;
  }

  Future<bool> _onChangeCampus(String name) async {
    if (_controller == null || _disposed) return false;
    bool flag = await _controller!.evaluateJavascript(source: '''
      var list = Array.from($_campusListSelector);
      var campus = list.filter((element) => element.innerText === '$name');
      if (campus.length === 0) {
        false;
      } else {
        campus[0].click();
        true;
      }
    ''');
    return flag;
  }
}
