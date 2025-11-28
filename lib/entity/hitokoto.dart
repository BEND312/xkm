import 'package:json_annotation/json_annotation.dart';

part 'hitokoto.g.dart';

@JsonSerializable()
class Hitokoto {
  Hitokoto({
    required this.id,
    required this.uuid,
    required this.hitokoto,
    required this.type,
    required this.from,
    this.fromWho,
    required this.creator,
    required this.creatorUid,
    required this.reviewer,
    required this.commitFrom,
    required this.createdAt,
    required this.length,
  });

  final int id;
  final String uuid;
  final String hitokoto;
  final String type;
  final String from;
  @JsonKey(name: 'from_who')
  final String? fromWho;
  final String creator;
  @JsonKey(name: 'creator_uid')
  final int creatorUid;
  final int reviewer;
  @JsonKey(name: 'commit_from')
  final String commitFrom;
  @JsonKey(name: 'created_at')
  final String createdAt;
  final int length;

  factory Hitokoto.fromJson(Map<String, dynamic> json) =>
      _$HitokotoFromJson(json);

  Map<String, dynamic> toJson() => _$HitokotoToJson(this);
}
