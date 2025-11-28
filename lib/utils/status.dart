enum Status {
  ok,
  partiallyOkWithToast,
  okWithToast,
  fail,
  failWithToast,
  permissionRequired,
  manualCaptchaRequired,
  captchaFailed,
  notAuthorized;
}

class StatusContainer<T> {
  final Status status;
  final T? value;
  final String? message;

  const StatusContainer(this.status, [this.value, this.message]);

  @override
  String toString() =>
      'status: ${status.toString()}, value: $value, message: $message';
}
