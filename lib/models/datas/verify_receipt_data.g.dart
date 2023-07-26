// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_receipt_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VerifyReceiptData _$VerifyReceiptDataFromJson(Map<String, dynamic> json) =>
    VerifyReceiptData(
      json['productId'] as String? ?? '',
      json['transactionId'] as String? ?? '',
      json['expirationTime'] as int? ?? 0,
    );

Map<String, dynamic> _$VerifyReceiptDataToJson(VerifyReceiptData instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'transactionId': instance.transactionId,
      'expirationTime': instance.expirationTime,
    };
