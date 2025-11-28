import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:swustmeow/services/boxes/webview_cookie_box.dart';

import 'global_service.dart';

class WebViewCookieService {
  Future<void> init() async {
    List<String>? keys =
        (WebViewCookieBox.get('keys') as List<dynamic>?)?.cast();

    if (keys != null) {
      for (final key in keys) {
        final cookies = WebViewCookieBox.get(key) as List<dynamic>?;
        if (cookies == null) continue;

        final cookiesCopy = List.from(cookies);
        for (final cookie in cookiesCopy) {
          final url = cookie['url'];
          final cookieName = cookie['name'];
          final cookieValue = cookie['value'];
          final host = cookie['host'];

          await GlobalService.webViewCookieManager?.setCookie(
            url: WebUri(url),
            name: cookieName,
            value: cookieValue,
            domain: host,
            path: '/',
          );
        }
      }
    }
  }

  /// 解析 `Cookie` 头并同步到 WebView
  Future<void> syncCookiesFromHeader(
    String key,
    Uri uri,
    String cookieHeader,
  ) async {
    final host = uri.host;

    List<String>? keys =
        (WebViewCookieBox.get('keys') as List<dynamic>?)?.cast() ?? [];
    var cachedCookies = WebViewCookieBox.get(key) as List<dynamic>? ?? [];

    List<String> cookiePairs = cookieHeader.split('; ');
    for (String cookie in cookiePairs) {
      List<String> parts = cookie.split('=');
      if (parts.length == 2) {
        String name = parts[0].trim();
        String value = parts[1].trim();
        await GlobalService.webViewCookieManager?.setCookie(
          url: WebUri.uri(uri),
          name: name,
          value: value,
          domain: host,
          path: '/',
        );

        if (!keys.contains(key)) {
          keys.add(key);
        }

        cachedCookies.removeWhere(
            (cookie) => (cookie as Map<dynamic, dynamic>)['host'] == uri.host);
        cachedCookies = [
          {
            'url': uri.toString(),
            'host': uri.host,
            'name': name,
            'value': value,
          },
          ...cachedCookies
        ];
      }
    }

    await WebViewCookieBox.put('keys', keys);
    await WebViewCookieBox.put(key, cachedCookies);
  }

  /// 解析 `Set-Cookie` 头并存入 WebView
  Future<void> setCookiesToWebView(
    String key,
    Uri uri,
    List<String> setCookieHeaders,
  ) async {
    List<String>? keys =
        (WebViewCookieBox.get('keys') as List<dynamic>?)?.cast() ?? [];
    var cachedCookies = WebViewCookieBox.get(uri.host) as List<dynamic>? ?? [];

    for (String cookie in setCookieHeaders) {
      List<String> cookieParts = cookie.split('; ');
      String? cookieName;
      String? cookieValue;
      String? domain;
      String path = '/';

      for (String part in cookieParts) {
        if (part.contains('=') && cookieName == null) {
          List<String> nameValue = part.split('=');
          cookieName = nameValue[0];
          cookieValue = nameValue.sublist(1).join('=');
        } else if (part.toLowerCase().startsWith('domain=')) {
          domain = part.split('=')[1];
        } else if (part.toLowerCase().startsWith('path=')) {
          path = part.split('=')[1];
        }
      }

      if (cookieName != null && cookieValue != null) {
        domain ??= uri.host;
        await GlobalService.webViewCookieManager?.setCookie(
          url: WebUri.uri(uri),
          name: cookieName,
          value: cookieValue,
          domain: domain,
          path: path,
        );

        if (!keys.contains(key)) {
          keys.add(key);
        }

        cachedCookies.removeWhere(
            (cookie) => (cookie as Map<dynamic, dynamic>)['host'] == uri.host);
        cachedCookies = [
          {
            'url': uri.toString(),
            'host': domain,
            'name': cookieName,
            'value': cookieValue,
          },
          ...cachedCookies
        ];

        await WebViewCookieBox.put('keys', keys);
        await WebViewCookieBox.put(key, cachedCookies);
      }
    }
  }

  Future<void> deleteCookieSet(String key) async {
    List<String>? keys =
        (WebViewCookieBox.get('keys') as List<dynamic>?)?.cast() ?? [];
    final cachedCookies = WebViewCookieBox.get(key) as List<dynamic>? ?? [];

    for (final cookie in cachedCookies) {
      final url = cookie['url'];
      final name = cookie['name'];

      await GlobalService.webViewCookieManager?.deleteCookie(
        url: WebUri(url),
        name: name,
        path: '/',
      );
    }

    keys.removeWhere((k) => k == key);
    await WebViewCookieBox.delete(key);
    await WebViewCookieBox.put('keys', keys);
  }
}
