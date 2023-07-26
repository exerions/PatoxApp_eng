// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_row.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResponseRow _$ResponseRowFromJson(Map<String, dynamic> json) => ResponseRow(
      json['success'] as bool,
      json['message'] as String,
      json['data'] as Map<String, dynamic>?,
      json['versatile'],
      json['moveUrl'] as String?,
      json['code'] as int,
    );

Map<String, dynamic> _$ResponseRowToJson(ResponseRow instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'versatile': instance.versatile,
      'moveUrl': instance.moveUrl,
      'code': instance.code,
    };
