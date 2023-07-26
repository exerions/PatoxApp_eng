// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
      json['id'] as int? ?? 0,
      json['user_level'] as int? ?? 0,
      json['name'] as String? ?? '',
      json['nickname'] as String? ?? '',
      json['email'] as String? ?? '',
      json['is_use_email'] == null
          ? false
          : converterFromIntToBool(json['is_use_email'] as int),
      json['phone_number'] as String? ?? '',
      json['mobile_number'] as String? ?? '',
      json['is_use_push'] == null
          ? false
          : converterFromIntToBool(json['is_use_push'] as int),
      json['profile'] as String? ?? '',
    );

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'id': instance.id,
      'user_level': instance.userLevel,
      'name': instance.name,
      'nickname': instance.nickname,
      'email': instance.email,
      'is_use_email': instance.isUseEmail,
      'phone_number': instance.phoneNumber,
      'mobile_number': instance.mobileNumber,
      'is_use_push': instance.isUsePush,
      'profile': instance.profile,
    };
