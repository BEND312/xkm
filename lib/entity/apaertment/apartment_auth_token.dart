import 'package:hive/hive.dart';

part 'apartment_auth_token.g.dart';

@HiveType(typeId: 21)
class ApartmentAuthToken {
  const ApartmentAuthToken({
    required this.tokenType,
    required this.token,
    required this.expireDate,
  });

  @HiveField(0)
  final String tokenType;
  @HiveField(1)
  final String token;
  @HiveField(2)
  final DateTime expireDate;
}
