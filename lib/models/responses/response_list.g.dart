// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResponseList _$ResponseListFromJson(Map<String, dynamic> json) => ResponseList(
      json['success'] as bool,
      json['message'] as String,
      (json['data'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      json['versatile'],
      json['moveUrl'] as String?,
      json['code'] as int,
    );

Map<String, dynamic> _$ResponseListToJson(ResponseList instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'versatile': instance.versatile,
      'moveUrl': instance.moveUrl,
      'code': instance.code,
    };
