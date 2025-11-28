enum SharedStatus {
  /// 共享正常
  ok,
  /// 共享记录不存在，可能是由于数据库迁移
  notFound('共享不存在');

  final String? description;

  const SharedStatus([this.description]);
}