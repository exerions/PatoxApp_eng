import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

bool isInitInstance = false;
late SharedPreferences preferences;

enum PreferencesKeys {
  // bool
  isLogin,
  isUseEmail,
  isUsePush,
  isPermissionMessageOutput,
  isSettingTicket,
  isCommentaryTicket,

  // int
  userId,
  userLevel,

  // string
  token,
  email,
  name,
  nickname,
  phoneNumber,
  mobileNumber,
  pushDevice,
  pushToken,
  profile,
}

Future<bool> initInstance() async {
  try {
    if (!isInitInstance) {
      preferences = await SharedPreferences.getInstance();
      isInitInstance = true;
    }
    return true;
  } catch (e) {
    return false;
  }
}

Future<bool> setBool(PreferencesKeys preferencesKey, bool value) async {
  await initInstance();
  return await preferences.setBool(preferencesKey.toString(), value);
}

bool getBool(PreferencesKeys preferencesKey, [bool defaultValue = false]) {
  return preferences.getBool(preferencesKey.toString()) ?? defaultValue;
}

Future<bool> setString(PreferencesKeys preferencesKey, String value) async {
  await initInstance();
  return await preferences.setString(preferencesKey.toString(), value);
}

String getString(PreferencesKeys preferencesKey, [String defaultValue = '']) {
  return preferences.getString(preferencesKey.toString()) ?? defaultValue;
}

Future<bool> setDouble(PreferencesKeys preferencesKey, double value) async {
  await initInstance();
  return await preferences.setDouble(preferencesKey.toString(), value);
}

double getDouble(PreferencesKeys preferencesKey, [double defaultValue = 0]) {
  return preferences.getDouble(preferencesKey.toString()) ?? defaultValue;
}

Future<bool> setInt(PreferencesKeys preferencesKey, int value) async {
  await initInstance();
  return await preferences.setInt(preferencesKey.toString(), value);
}

int getInt(PreferencesKeys preferencesKey, [int defaultValue = 0]) {
  return preferences.getInt(preferencesKey.toString()) ?? defaultValue;
}

Future<bool> setStringList(PreferencesKeys preferencesKey, List<String> value) async {
  await initInstance();
  return await preferences.setStringList(preferencesKey.toString(), value);
}

List<String>? getStringList(PreferencesKeys preferencesKey) {
  return preferences.getStringList(preferencesKey.toString());
}

Future<bool> remove(PreferencesKeys preferencesKey) async {
  await initInstance();
  return await preferences.remove(preferencesKey.toString());
}
