import 'package:dio/dio.dart';
import 'package:swustmeow/services/global_service.dart';

class DioCookieInterceptor extends Interceptor {
  final String key;

  const DioCookieInterceptor({required this.key});

  /// 请求拦截器：提取 `Cookie` 头并同步到 WebView
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    Uri uri = options.uri;

    // 提取 `Cookie` 请求头
    if (options.headers.containsKey('Cookie')) {
      var cookieHeader = options.headers['Cookie'];
      if (cookieHeader != null) {
        if (cookieHeader is Map) {
          cookieHeader = cookieHeader.keys
              .map((key) => '$key=${cookieHeader[key]}')
              .join('; ');
        }

        await GlobalService.webViewCookieService
            ?.syncCookiesFromHeader(key, uri, cookieHeader);
      }
    }

    handler.next(options);
  }

  /// 响应拦截器：提取 `Set-Cookie` 头并存入 WebView
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    List<String>? setCookieHeaders = response.headers.map['set-cookie'];
    if (setCookieHeaders != null) {
      await GlobalService.webViewCookieService?.setCookiesToWebView(
          key, response.requestOptions.uri, setCookieHeaders);
    }
    handler.next(response);
  }
}
