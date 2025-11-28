import 'package:json_annotation/json_annotation.dart';

part 'response_entity.g.dart';

@JsonSerializable()
class ResponseEntity<T> {
  const ResponseEntity({required this.code, required this.message, this.data});

  final int code;
  final String message;
  @JsonKey(fromJson: _dataFromJson, toJson: _dataToJson)
  final T? data;

  static T _dataFromJson<T>(Object json) => json as T;

  static Object _dataToJson<T>(T object) => object as Object;

  factory ResponseEntity.fromJson(Map<String, dynamic> json) =>
      _$ResponseEntityFromJson(json);
}
