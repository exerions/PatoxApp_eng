// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_interface.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// ignore_for_file: always_put_control_body_on_new_line, always_specify_types, prefer_const_declarations, unnecessary_brace_in_string_interps
class _$GeneralRowService extends GeneralRowService {
  _$GeneralRowService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final definitionType = GeneralRowService;

  @override
  Future<Response<ResponseRow>> getRefreshToken(Map<String, dynamic> body) {
    final $url = 'appApi/user/refreshToken';
    final $body = body;
    final $request = Request(
      'POST',
      //Uri.parse($url),
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<ResponseRow, ResponseRow>($request);
  }

  @override
  Future<Response<ResponseRow>> getUser(Map<String, dynamic> body) {
    final $url = 'appApi/user/getUser';
    final $body = body;
    final $request = Request(
      'POST',
      //Uri.parse($url),
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<ResponseRow, ResponseRow>($request);
  }

  @override
  Future<Response<ResponseRow>> appVerifyReceipt(Map<String, dynamic> body) {
    final $url = 'appApi/user/appVerifyReceipt';
    final $body = body;
    final $request = Request(
      'POST',
      //Uri.parse($url),
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<ResponseRow, ResponseRow>($request);
  }
}

// ignore_for_file: always_put_control_body_on_new_line, always_specify_types, prefer_const_declarations, unnecessary_brace_in_string_interps
class _$GeneralListService extends GeneralListService {
  _$GeneralListService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final definitionType = GeneralListService;
}
