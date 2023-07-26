import 'dart:async';

import 'package:chopper/chopper.dart';
import 'package:patox/services/chopper/service_interface.dart';
import 'package:patox/utils/logger.dart';

typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

class JsonConverterData<T> extends JsonConverter {
  final Map<Type, JsonFactory> factories;

  const JsonConverterData(this.factories);

  List<T> decodeList<T>(List values) {
    try {
      return values.where((v) => v != null).map<T>((v) => decode<T>(v)).toList();
    } catch (e) {
      displayNetworkErrorMessage(null, e);
      throw const FormatException('API Decode 오류');
    }
  }

  T decodeMap<T>(values) {
    try {
      final jsonFactory = factories[T];

      if (jsonFactory == null || jsonFactory is! JsonFactory<T>) {
        throw const FormatException('DATA_ERROR');
      }

      return jsonFactory(values);
    } catch (e) {
      logger.e(values);
      displayNetworkErrorMessage(null, e);
      throw const FormatException('API Decode 오류');
    }
  }

  dynamic decode<T>(entity) {
    try {
      if (entity != null) {
        if (entity is Iterable) {
          return decodeList<T>(entity as List<T>);
        } else if (entity is Map) {
          return decodeMap<T>(entity as Map<String, dynamic>?);
        }
      }
      return entity;
    } catch (e) {
      logger.e(entity);
      displayNetworkErrorMessage(null, e);
      throw const FormatException('API Decode 오류');
    }
  }

@override
Response<ResultType> convertResponse<ResultType, InnerType>(Response response) {
  final jsonResponse = super.convertResponse(response);
  try {
    return jsonResponse.copyWith<ResultType>(body: decode<InnerType>(jsonResponse.body));
  } catch (e) {
    logger.e(jsonResponse.body);
    displayNetworkErrorMessage(null, e);
    throw const FormatException('API 통신 오류');
  }
}

// @override
  // Response<ResultType> convertResponse<ResultType, InnerType>(Response response) {
  //   final jsonResponse = super.convertResponse(response);
  //   try {
  //     return jsonResponse.copyWith<ResultType>(body: decode<InnerType>(jsonResponse.body));
  //   } catch (e) {
  //     logger.e(jsonResponse.body);
  //     displayNetworkErrorMessage(null, e);
  //     throw const FormatException('API 통신 오류');
  //   }
  // }
}
