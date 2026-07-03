import 'dart:async';
import 'options.dart';
import 'response.dart';
import 'error.dart';

class Interceptor {
  FutureOr<MiniRequestOptions> onRequest(MiniRequestOptions options) => options;
  FutureOr<MiniResponse> onResponse(MiniResponse response) => response;
  FutureOr<dynamic> onError(MiniError error) => throw error;
}
