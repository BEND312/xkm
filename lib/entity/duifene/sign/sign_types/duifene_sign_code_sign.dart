import 'package:swustmeow/entity/duifene/sign/sign_types/duifene_sign_base.dart';

class DuiFenESignCodeSign extends DuiFenESignBase {
  final String signCode;

  const DuiFenESignCodeSign({
    required super.id,
    required super.secondsRemaining,
    required this.signCode,
  });
}
