import 'package:json_annotation/json_annotation.dart';

part 'auth_data.g.dart';

@JsonSerializable()
class AuthData {
  int userId = 0;
  String token = '';

  AuthData([
    this.userId = 0,
    this.token = '',
  ]);

  static const fromJson = _$AuthDataFromJson;

  Map<String, dynamic> toJson() => _$AuthDataToJson(this);
}
