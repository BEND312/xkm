import 'package:swustmeow/entity/duifene/sign/sign_types/duifene_sign_base.dart';

class DuiFenELocationSign extends DuiFenESignBase {
  final double longitude;
  final double latitude;

  const DuiFenELocationSign({
    required super.id,
    required super.secondsRemaining,
    required this.longitude,
    required this.latitude,
  });
}
