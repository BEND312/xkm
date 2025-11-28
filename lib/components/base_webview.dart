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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:swustmeow/data/m_theme.dart';
import 'package:swustmeow/services/permission_service.dart';
import 'package:swustmeow/utils/common.dart';

class BaseWebView extends StatefulWidget {
  const BaseWebView({
    super.key,
    required this.url,
    this.onLoadStart,
    this.onLoadStop,
    this.onUpdateVisitedHistory,
    this.onTitleChanged,
    this.onDispose,
  });

  final String url;
  final Function(InAppWebViewController controller, WebUri? url)? onLoadStart;
  final Function(InAppWebViewController controller, WebUri? url)? onLoadStop;
  final Function(
          InAppWebViewController controller, WebUri? url, bool? isReload)?
      onUpdateVisitedHistory;
  final Function(InAppWebViewController controller, String? title)?
      onTitleChanged;
  final Function()? onDispose;

  @override
  State<StatefulWidget> createState() => _BaseWebViewState();
}

class _BaseWebViewState extends State<BaseWebView> {
  InAppWebViewController? _webViewController;
  PullToRefreshController? _pullToRefreshController;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _pullToRefreshController = kIsWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(color: MTheme.primary2),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                _webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                _webViewController?.loadUrl(
                  urlRequest:
                      URLRequest(url: await _webViewController?.getUrl()),
                );
              }
            },
          );
  }

  @override
  void dispose() {
    _webViewController?.dispose();

    if (widget.onDispose != null) {
      widget.onDispose!();
    }

    // _pullToRefreshController?.dispose();
    super.dispose();
  }

  void _injectBlobInterceptor(InAppWebViewController controller) {
    final jsCode = '''
      (function() {
        const originalCreateObjectURL = URL.createObjectURL;
        window._blobDataMap = window._blobDataMap || new Map();
        URL.createObjectURL = function(blob) {
          const blobUrl = originalCreateObjectURL.call(this, blob);
          if (blob.type === 'application/pdf') {
            window._blobDataMap.set(blobUrl, blob);
          }
          
          return blobUrl;
        };
      })();
    ''';
    
    controller.evaluateJavascript(source: jsCode);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri(widget.url)),
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            geolocationEnabled: true,
            sharedCookiesEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
          ),
          pullToRefreshController: _pullToRefreshController,
          onWebViewCreated: (controller) {
            _webViewController = controller;
            controller.addJavaScriptHandler(
              handlerName: 'getBlobData',
              callback: (args) {
              },
            );
          },
          onLoadStart: (controller, url) {
            if (widget.onLoadStart != null) {
              widget.onLoadStart!(controller, url);
            }

            setState(() {
              _progress = 0.0;
            });
          },
          onLoadStop: (controller, url) {
            if (widget.onLoadStop != null) {
              widget.onLoadStop!(controller, url);
            }

            _pullToRefreshController?.endRefreshing();
            setState(() => _progress = 1.0);
            _injectBlobInterceptor(controller);
          },
          onProgressChanged: (controller, progress) {
            if (progress == 100) {
              _pullToRefreshController?.endRefreshing();
            }

            setState(() => _progress = progress / 100);
          },
          onUpdateVisitedHistory: (controller, url, isReload) {
            if (widget.onUpdateVisitedHistory != null) {
              widget.onUpdateVisitedHistory!(controller, url, isReload);
            }
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          onGeolocationPermissionsShowPrompt: (controller, origin) async {
            return GeolocationPermissionShowPromptResponse(
                allow: true, origin: origin, retain: true);
          },
          onTitleChanged: (controller, title) {
            if (widget.onTitleChanged != null) {
              widget.onTitleChanged!(controller, title);
            }
          },
          onDownloadStartRequest: (controller, downloadStartRequest) async {
            final url = downloadStartRequest.url.toString();
            final mimeType = downloadStartRequest.mimeType;
            final suggestedFilename = downloadStartRequest.suggestedFilename ?? 'download';
            if (url.startsWith('blob:')) {
              try {
                if (Platform.isAndroid) {
                  final status = await PermissionService.requestPermission(Permission.storage);
                  if (!status.isGranted) {
                    if (status.isPermanentlyDenied) {
                      showErrorToast('请在设置中允许存储权限');
                      await openAppSettings();
                    } else {
                      showErrorToast('需要存储权限才能下载文件');
                    }
                    return;
                  }
                }
                
                showInfoToast('正在准备下载...');
                final callbackName = 'flutterBlobCallback_${DateTime.now().millisecondsSinceEpoch}';
                
                // 先注册Dart回调
                String? base64Result;
                controller.addJavaScriptHandler(
                  handlerName: callbackName,
                  callback: (args) {
                    if (args.isNotEmpty) {
                      base64Result = args[0].toString();
                    }
                  },
                );
                final jsCode = '''
                  (function() {
                    const blobUrl = '$url';
                    const blob = window._blobDataMap ? window._blobDataMap.get(blobUrl) : null;
                    
                    if (!blob) {
                      window.flutter_inappwebview.callHandler('$callbackName', 'ERROR:Blob not found in cache');
                      return;
                    }
                    
                    const reader = new FileReader();
                    reader.onloadend = function() {
                      window.flutter_inappwebview.callHandler('$callbackName', reader.result);
                    };
                    reader.onerror = function(e) {
                      window.flutter_inappwebview.callHandler('$callbackName', 'ERROR:FileReader failed: ' + e.toString());
                    };
                    reader.readAsDataURL(blob);
                  })();
                ''';
                
                await controller.evaluateJavascript(source: jsCode);
                int waitTime = 0;
                while (base64Result == null && waitTime < 10000) {
                  await Future.delayed(const Duration(milliseconds: 100));
                  waitTime += 100;
                }

                controller.removeJavaScriptHandler(handlerName: callbackName);
                
                if (base64Result == null) {
                  showErrorToast('下载失败：获取数据超时');
                  return;
                }
                String base64String = base64Result!;
                if (base64String.startsWith('"') && base64String.endsWith('"')) {
                  base64String = base64String.substring(1, base64String.length - 1);
                }
                if (base64String.startsWith('ERROR:')) {
                  showErrorToast('下载失败：${base64String.substring(6)}');
                  return;
                }
                
                if (!base64String.contains(',')) {
                  showErrorToast('下载失败：数据格式错误');
                }
                final base64Data = base64String.split(',')[1];
                final bytes = base64Decode(base64Data);
                Directory? directory;
                if (Platform.isAndroid) {
                  // Android使用公共Downloads目录
                  directory = Directory('/storage/emulated/0/Download');
                  if (!await directory.exists()) {
                    directory = await getExternalStorageDirectory();
                  }
                } else {
                  directory = await getApplicationDocumentsDirectory();
                }
                
                if (directory == null) {
                  showErrorToast('下载失败：无法访问存储目录');
                  return;
                }
                String filename = suggestedFilename;
                if (mimeType != null && !filename.contains('.')) {
                  if (mimeType == 'application/pdf') {
                    filename += '.pdf';
                  } else if (mimeType.startsWith('image/')) {
                    filename += '.${mimeType.split('/')[1]}';
                  }
                }
                final filePath = '${directory.path}/$filename';
                final file = File(filePath);
                await file.writeAsBytes(bytes);
                
                showSuccessToast('文件已保存到：Download/$filename');
              } catch (e) {
                showErrorToast('下载失败：$e');
              }
            } else {
              showInfoToast('正在下载文件...');
            }
          },
        ),
        if (_progress < 1.0)
          LinearProgressIndicator(
            value: _progress,
            color: MTheme.primary1,
          ),
      ],
    );
  }
}
