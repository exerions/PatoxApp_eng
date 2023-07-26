import 'package:json_annotation/json_annotation.dart';

part 'response_list.g.dart';

@JsonSerializable()
class ResponseList {
  final bool success;
  final String message;
  final List<Map<String, dynamic>>? data;
  final dynamic versatile;
  final String? moveUrl;
  final int code;

  ResponseList(this.success, this.message, this.data, this.versatile, this.moveUrl, this.code);

  static const fromJson = _$ResponseListFromJson;

  Map<String, dynamic> toJson() => _$ResponseListToJson(this);
}
