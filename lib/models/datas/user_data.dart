import 'package:json_annotation/json_annotation.dart';
import 'package:patox/utils/converter_util.dart';

part 'user_data.g.dart';

@JsonSerializable()
class UserData {
  int id = 0;
  @JsonKey(
    name: 'user_level',
  )
  int userLevel = 0;
  String name = '';
  String? nickname = '';
  String email = '';
  @JsonKey(
    name: 'is_use_email',
    fromJson: converterFromIntToBool,
  )
  bool isUseEmail = false;
  @JsonKey(name: 'phone_number')
  String? phoneNumber = '';
  @JsonKey(name: 'mobile_number')
  String? mobileNumber = '';
  @JsonKey(
    name: 'is_use_push',
    fromJson: converterFromIntToBool,
  )
  bool isUsePush = false;
  String? profile = '';

  UserData([
    this.id = 0,
    this.userLevel = 0,
    this.name = '',
    this.nickname = '',
    this.email = '',
    this.isUseEmail = false,
    this.phoneNumber = '',
    this.mobileNumber = '',
    this.isUsePush = false,
    this.profile = '',
  ]);

  static const fromJson = _$UserDataFromJson;

  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}
