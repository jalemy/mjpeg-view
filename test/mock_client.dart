import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart';

class MockClient implements Client {
  final StreamController<List<int>> controller;
  final int statusCode;

  MockClient({
    required this.controller,
    required this.statusCode,
  });

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    return Future.value(StreamedResponse(controller.stream, statusCode));
  }

  @override
  void close() {
    controller.close();
  }

  // --- 以下、テストでは利用しないが実装が必要なメソッドたち ---

  @override
  Future<Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    throw UnimplementedError();
  }

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<Response> head(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    throw UnimplementedError();
  }

  @override
  Future<Response> post(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    throw UnimplementedError();
  }

  @override
  Future<Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    throw UnimplementedError();
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) {
    throw UnimplementedError();
  }
}
