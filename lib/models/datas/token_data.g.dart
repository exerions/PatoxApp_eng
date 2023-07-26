// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenData _$TokenDataFromJson(Map<String, dynamic> json) => TokenData(
      json['iat'] as int? ?? 0,
      json['exp'] as int? ?? 0,
      json['nbf'] as int? ?? 0,
      json['jti'] as String? ?? '',
      json['sub'] as String? ?? '',
    );

Map<String, dynamic> _$TokenDataToJson(TokenData instance) => <String, dynamic>{
      'iat': instance.iat,
      'exp': instance.exp,
      'nbf': instance.nbf,
      'jti': instance.jti,
      'sub': instance.sub,
    };
