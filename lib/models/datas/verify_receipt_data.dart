import 'package:json_annotation/json_annotation.dart';

part 'verify_receipt_data.g.dart';

@JsonSerializable()
class VerifyReceiptData {
  String productId = '';
  String transactionId = '';
  int expirationTime = 0;

  VerifyReceiptData([
    this.productId = '',
    this.transactionId = '',
    this.expirationTime = 0,
  ]);

  static const fromJson = _$VerifyReceiptDataFromJson;

  Map<String, dynamic> toJson() => _$VerifyReceiptDataToJson(this);
}
