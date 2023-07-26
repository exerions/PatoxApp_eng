import 'package:json_annotation/json_annotation.dart';

part 'response_row.g.dart';

@JsonSerializable()
class ResponseRow {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final dynamic versatile;
  final String? moveUrl;
  final int code;

  ResponseRow(this.success, this.message, this.data, this.versatile, this.moveUrl, this.code);

  static const fromJson = _$ResponseRowFromJson;

  Map<String, dynamic> toJson() => _$ResponseRowToJson(this);
}
