import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:patox/models/datas/auth_data.dart';
import 'package:patox/models/datas/token_data.dart';
import 'package:patox/models/datas/user_data.dart';
import 'package:patox/models/datas/verify_receipt_data.dart';
import 'package:patox/models/responses/response_row.dart';
import 'package:patox/services/chopper/service_interface.dart';
import 'package:patox/utils/logger.dart';
import 'package:patox/utils/preferences_util.dart' as preference_util;
import 'package:provider/provider.dart';

class UserUtil {
  static bool isLoginLoad = false;
  static bool isLogin = false;
  static String token = '';
  static String pushDevice = '';
  static String pushToken = '';
  static bool isSettingTicketLoad = false;
  static bool isSettingTicket = false;
  static bool isCommentaryTicketLoad = false;
  static bool isCommentaryTicket = false;
}

bool isLogin() {
  try {
    if (!UserUtil.isLoginLoad) {
      UserUtil.isLogin = preference_util.getBool(preference_util.PreferencesKeys.isLogin);
      UserUtil.isLoginLoad = true;
    }
  } catch (e) {
    logger.e(e);
  }

  return UserUtil.isLogin;
}

Future<void> setLoginState(bool loginState) async {
  try {
    if (isLogin()) {
      if (!loginState) {
        UserUtil.isLogin = false;
        await preference_util.setBool(preference_util.PreferencesKeys.isLogin, false);
        return;
      }
    } else {
      if (loginState) {
        UserUtil.isLogin = true;
        await preference_util.setBool(preference_util.PreferencesKeys.isLogin, true);
        return;
      }
    }
  } catch (e) {
    logger.e(e);
  }
  return;
}

Future<void> setLogin(String token, [int userId = 0]) async {
  try {
    if (token.length < 100) {
      throw const FormatException('잘못된 토큰 입니다.');
    }

    if (JwtDecoder.isExpired(token)) {
      throw const FormatException('토큰 유효기간 만료.');
    }

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    TokenData tokenData = TokenData.fromJson(decodedToken);
    int tokenUserId = int.parse(tokenData.sub);

    if (userId > 0) {
      if (tokenUserId != userId) {
        throw const FormatException('토큰과 고유번호가 일치하지 않습니다.');
      }
    }

    await setLoginState(true);
    await setToken(token);
    await preference_util.setInt(preference_util.PreferencesKeys.userId, tokenUserId);
  } catch (e) {
    await setLogout();
    logger.e(e);
  }
}

Future<void> setLogout() async {
  try {
    await setLoginState(false);
    await setToken('');
    await preference_util.remove(preference_util.PreferencesKeys.userId);
    preference_util.remove(preference_util.PreferencesKeys.userLevel);
    preference_util.remove(preference_util.PreferencesKeys.name);
    preference_util.remove(preference_util.PreferencesKeys.nickname);
    preference_util.remove(preference_util.PreferencesKeys.email);
    preference_util.remove(preference_util.PreferencesKeys.isUseEmail);
    preference_util.remove(preference_util.PreferencesKeys.phoneNumber);
    preference_util.remove(preference_util.PreferencesKeys.mobileNumber);
    preference_util.remove(preference_util.PreferencesKeys.isUsePush);
    preference_util.remove(preference_util.PreferencesKeys.profile);
  } catch (e) {
    logger.e(e);
  }
}

Future<void> setToken(String token) async {
  try {
    UserUtil.token = token;
    await preference_util.setString(preference_util.PreferencesKeys.token, token);
  } catch (e) {
    logger.e(e);
  }
}

String getToken() {
  try {
    if (UserUtil.token.isEmpty) {
      UserUtil.token = preference_util.getString(preference_util.PreferencesKeys.token);
    }
  } catch (e) {
    logger.e(e);
  }

  return UserUtil.token;
}

Future<void> setPushDevice(String pushDevice) async {
  try {
    UserUtil.pushDevice = pushDevice;
    await preference_util.setString(preference_util.PreferencesKeys.pushDevice, pushDevice);
  } catch (e) {
    logger.e(e);
  }
}

String getPushDevice() {
  try {
    if (UserUtil.pushDevice.isEmpty) {
      UserUtil.pushDevice = preference_util.getString(preference_util.PreferencesKeys.pushDevice);

      if (UserUtil.pushDevice.isEmpty) {
        if (Platform.isAndroid) {
          setPushDevice('android');
        } else if (Platform.isIOS) {
          setPushDevice('ios');
        } else {
          setPushDevice('etc');
        }
      }
    }
  } catch (e) {
    logger.e(e);
  }

  return UserUtil.pushDevice;
}

Future<void> setPushToken(String pushToken) async {
  try {
    UserUtil.pushToken = pushToken;
    await preference_util.setString(preference_util.PreferencesKeys.pushToken, pushToken);
  } catch (e) {
    logger.e(e);
  }
}

String getPushToken() {
  try {
    if (UserUtil.pushToken.isEmpty) {
      UserUtil.pushToken = preference_util.getString(preference_util.PreferencesKeys.pushToken);
    }
  } catch (e) {
    logger.e(e);
  }

  return UserUtil.pushToken;
}

Future<void> setSettingTicket(bool isSettingTicket) async {
  try {
    UserUtil.isSettingTicket = isSettingTicket;
    await preference_util.setBool(preference_util.PreferencesKeys.isSettingTicket, isSettingTicket);
  } catch (e) {
    logger.e(e);
  }
}

bool isSettingTicket() {
  try {
    if (!UserUtil.isSettingTicketLoad) {
      UserUtil.isSettingTicket = preference_util.getBool(preference_util.PreferencesKeys.isSettingTicket);
      UserUtil.isSettingTicketLoad = true;
    }
  } catch (e) {
    logger.e(e);
  }

  return UserUtil.isSettingTicket;
}

Future<void> setCommentaryTicket(bool isCommentaryTicket) async {
  try {
    UserUtil.isCommentaryTicket = isCommentaryTicket;
    await preference_util.setBool(preference_util.PreferencesKeys.isCommentaryTicket, isCommentaryTicket);
  } catch (e) {
    logger.e(e);
  }
}

bool isCommentaryTicket() {
  try {
    if (!UserUtil.isCommentaryTicketLoad) {
      UserUtil.isCommentaryTicket = preference_util.getBool(preference_util.PreferencesKeys.isCommentaryTicket);
      UserUtil.isCommentaryTicketLoad = true;
    }
  } catch (e) {
    logger.e(e);
  }

  return UserUtil.isCommentaryTicket;
}

Future<void> getRefreshToken(BuildContext context, Function callback) async {
  try {
    final inputData = {
      'push_device': getPushDevice(),
      'push_token': getPushToken(),
      'is_setting_ticket': isSettingTicket(),
      'is_commentary_ticket': isCommentaryTicket(),
    };

    GeneralRowService generalRowService = Provider.of<GeneralRowService>(context, listen: false);
    final response = await generalRowService.getRefreshToken(inputData);
    bool success = displayResponseErrorMessage(context, response);

    if (success) {
      ResponseRow? body = response.body;

      if (body != null) {
        Map<String, dynamic>? data = body.data;

        if (data != null) {
          callback(AuthData.fromJson(data));
          return;
        }
      }
    } else if (isLogin()) {
      await setLogout();
    }
  } catch (e) {
    displayNetworkErrorMessage(context, e);
  }

  try {} catch (e) {
    logger.e(e);
  }

  callback(null);
}

Future<void> setRefreshToken(AuthData? authData) async {
  try {
    if (authData == null) {
      return;
    }

    await setLogin(authData.token, authData.userId);
  } catch (e) {
    logger.e(e);
  }
}

Future<void> getUser(BuildContext context, Function callback) async {
  try {
    final inputData = {
      'push_device': getPushDevice(),
      'push_token': getPushToken(),
      'is_setting_ticket': isSettingTicket(),
      'is_commentary_ticket': isCommentaryTicket(),
    };

    GeneralRowService generalRowService = Provider.of<GeneralRowService>(context, listen: false);
    final response = await generalRowService.getUser(inputData);
    bool success = displayResponseErrorMessage(context, response);

    if (success) {
      ResponseRow? body = response.body;

      if (body != null) {
        Map<String, dynamic>? data = body.data;

        if (data != null) {
          callback(UserData.fromJson(data));
          return;
        }
      }
    } else if (isLogin()) {
      await setLogout();
    }
  } catch (e) {
    displayNetworkErrorMessage(context, e);
  }
  callback(null);
}

Future<void> appVerifyReceipt(BuildContext context, Function callback, String device, String? purchaseId, String verificationData, [String signature = '']) async {
  try {
    final inputData = {
      'device': device,
      'purchaseId': purchaseId ?? '',
      'verificationData': verificationData,
      'signature': signature,
    };

    GeneralRowService generalRowService = Provider.of<GeneralRowService>(context, listen: false);
    final response = await generalRowService.appVerifyReceipt(inputData);
    final body = response.body;

    if (body is ResponseRow) {
      final success = body.success;

      if (success) {
        ResponseRow? body = response.body;

        if (body != null) {
          Map<String, dynamic>? data = body.data;

          if (data != null) {
            callback(VerifyReceiptData.fromJson(data));
            return;
          }
        }
      }
    }
  } catch (e) {
    displayNetworkErrorMessage(context, e);
  }
  callback(null);
}

Future<void> setUser(UserData inputData) async {
  try {
    await preference_util.setInt(preference_util.PreferencesKeys.userId, inputData.id);
    preference_util.setInt(preference_util.PreferencesKeys.userLevel, inputData.userLevel);
    preference_util.setString(preference_util.PreferencesKeys.name, inputData.name);
    preference_util.setString(preference_util.PreferencesKeys.nickname, inputData.nickname ?? '');
    await preference_util.setString(preference_util.PreferencesKeys.email, inputData.email);
    preference_util.setBool(preference_util.PreferencesKeys.isUseEmail, inputData.isUseEmail);
    preference_util.setString(preference_util.PreferencesKeys.phoneNumber, inputData.phoneNumber ?? '');
    preference_util.setString(preference_util.PreferencesKeys.mobileNumber, inputData.mobileNumber ?? '');
    preference_util.setBool(preference_util.PreferencesKeys.isUsePush, inputData.isUsePush);
    preference_util.setString(preference_util.PreferencesKeys.profile, inputData.profile ?? '');
  } catch (e) {
    logger.e(e);
  }
}
