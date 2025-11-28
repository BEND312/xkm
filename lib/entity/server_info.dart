import 'package:hive/hive.dart';

part 'server_info.g.dart';

@HiveType(typeId: 4)
class ServerInfo {
  const ServerInfo({
    required this.activitiesUrl,
    required this.termDatesUrl,
  });

  @HiveField(0)
  final String activitiesUrl;

  @HiveField(1)
  final String termDatesUrl;

  factory ServerInfo.fromJson(
    Map<String, dynamic> json, {
    required ServerInfo fallback,
  }) =>
      _$ServerInfoFromJson(json) ?? fallback;

  static ServerInfo? _$ServerInfoFromJson(Map<String, dynamic> json) {
    try {
      return ServerInfo(
        activitiesUrl: json['activities_url'] as String? ?? '',
        termDatesUrl: json['term_dates_url'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
