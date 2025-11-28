enum DuiFenESignInStatus {
  /// 初始化中
  initializing,

  /// 等待上课
  waiting,

  /// 已上课，等待签到
  watching,

  /// 签到中
  signing,

  /// 已停止
  stopped,

  /// 未登录
  notAuthorized;
}