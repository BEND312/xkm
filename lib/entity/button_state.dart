enum ButtonState {
  ok,
  dissatisfied,
  error,
  loading;
}

class ButtonStateContainer {
  final ButtonState state;
  final String? message;
  final bool? withCaptcha;
  final String? captcha;

  const ButtonStateContainer(
    this.state, {
    this.message,
    this.withCaptcha,
    this.captcha,
  });
}
