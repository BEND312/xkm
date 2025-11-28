import 'dart:async';

class VibrationThrottlingUtil {
  static Timer? _debounceTimer;

  /// 函数防抖，[delay] 的单位为毫秒
  static void debounce(Function function, [int delay = 500]) {
    if (_debounceTimer != null) _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: delay), () {
      function();
      _debounceTimer = null;
    });
  }
}
