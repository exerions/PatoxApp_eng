import 'package:json_annotation/json_annotation.dart';

part 'token_data.g.dart';

@JsonSerializable()
class TokenData {
  int iat = 0;
  int exp = 0;
  int nbf = 0;
  String jti = '';
  String sub = '';

  TokenData([
    this.iat = 0,
    this.exp = 0,
    this.nbf = 0,
    this.jti = '',
    this.sub = '',
  ]);

  static const fromJson = _$TokenDataFromJson;

  Map<String, dynamic> toJson() => _$TokenDataToJson(this);
}
