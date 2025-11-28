/// 从 Set-Cookie 字符串中获取指定 Cookie 的值。
///
/// 该函数解析 Set-Cookie 字符串，并返回指定 Cookie 名称对应的值。
/// 如果 Set-Cookie 字符串为空或未找到指定的 Cookie，则返回 null。
///
/// 例如，对于 Set-Cookie 字符串 "SESSION=966ca6d3-3f53-47ed-aded-1456ba39ccfb; route=84ed423ca913e3bb637a88a8b62462f6"，
/// 调用 `getCookieValue(setCookie, 'SESSION')` 将返回 "966ca6d3-3f53-47ed-aded-1456ba39ccfb"。
///
/// @param setCookie  包含 Set-Cookie 信息的字符串。可以为空字符串，但不能为 null。
/// @param cookieName 要查找的 Cookie 名称。
/// @return  指定 Cookie 的值，如果未找到则返回 null。
///          如果 `setCookie` 为空字符串，也返回 null。
String? getCookieValue(String? setCookie, String cookieName) {
  if (setCookie == null || setCookie.isEmpty) {
    return null;
  }

  List<String> cookies = setCookie.split(';');
  for (String cookie in cookies) {
    cookie = cookie.trim();
    List<String> parts = cookie.split('=');
    if (parts.length != 2) {
      continue; // 跳过格式不正确的cookie项 (没有等号)
    }
    String name = parts[0].trim();
    String value = parts[1].trim();
    if (name == cookieName) {
      return value;
    }
  }
  return null;
}
