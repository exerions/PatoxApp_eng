import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:flutter/material.dart';
import 'package:http/src/base_request.dart';
import 'package:patox/main.dart';
import 'package:patox/models/responses/response_list.dart';
import 'package:patox/models/responses/response_row.dart';
import 'package:patox/services/chopper/json_converter_data.dart';
import 'package:patox/utils/common_util.dart' as common_util;
import 'package:patox/utils/logger.dart';
import 'package:patox/utils/user_util.dart' as user_util;

part 'service_interface.chopper.dart';

ChopperClient getChopperClient(service, converter) {
  return ChopperClient(
    //baseUrl: Uri.parse(WebViewApp.siteUrl),
    baseUrl: WebViewApp.siteUrl,
    converter: converter,
    errorConverter: converter,
    interceptors: [
      (Request request) async {
        try {
          request.headers['Authorization'] = 'Bearer ${user_util.getToken()}';
          request.headers['accept'] = 'application/json';
        } catch (e) {
          logger.e(e);
        }
        return request;
      },
    ],
    services: [service],
  );
}

displayNetworkErrorMessage(BuildContext? context, e) {
  String? errorMessage;

  if (e is SocketException) {
    errorMessage = e.osError?.message.toString();
  } else if (e is ArgumentError) {
    errorMessage = e.message.toString();
  } else {
    errorMessage = e.toString();
  }

  if (errorMessage != null) {
    if (context != null) {
      common_util.displayMessageDialog(context, '오류', errorMessage);
    } else {
      logger.e(errorMessage);
    }
  } else {
    logger.e(e);
  }
}

bool displayResponseErrorMessage(BuildContext context, Response response) {
  Object? error = response.error;
  String? errorMessage;

  if (error != null) {
    if (error.toString().substring(0, 5) == 'JWT: ') {
      user_util.setLogout();
      return false;
    }
  }

  try {
    final body = response.body;

    if (body is ResponseRow) {
      if (!body.success) {
        errorMessage = body.message;
      }
    } else if (body is ResponseList) {
      if (!body.success) {
        errorMessage = body.message;
      }
    }
  } catch (e) {
    BaseRequest? baseRequest = response.base.request;

    if (baseRequest != null) {
      errorMessage = response.error.toString();
    }
  }

  if (errorMessage != null && errorMessage.isNotEmpty) {
    if (errorMessage.substring(0, 5) == 'JWT: ') {
      user_util.setLogout();
      return false;
    }

    common_util.displayMessageDialog(context, '알림', errorMessage);
  }

  return errorMessage == null;
}

@ChopperApi(baseUrl: 'appApi/')
abstract class GeneralRowService extends ChopperService {
  static create() {
    return _$GeneralRowService(getChopperClient(_$GeneralRowService(), JsonConverterData({ResponseRow: (jsonData) => ResponseRow.fromJson(jsonData)})));
  }

  @Post(path: 'user/refreshToken')
  Future<Response<ResponseRow>> getRefreshToken(@Body() Map<String, dynamic> body);

  @Post(path: 'user/getUser')
  Future<Response<ResponseRow>> getUser(@Body() Map<String, dynamic> body);

  @Post(path: 'user/appVerifyReceipt')
  Future<Response<ResponseRow>> appVerifyReceipt(@Body() Map<String, dynamic> body);
}

@ChopperApi(baseUrl: 'appApi/')
abstract class GeneralListService extends ChopperService {
  static create() {
    return _$GeneralListService(getChopperClient(_$GeneralListService(), JsonConverterData({ResponseList: (jsonData) => ResponseList.fromJson(jsonData)})));
  }
}
