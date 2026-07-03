import 'options.dart';

class MiniResponse<T> {
  final T? data;
  final int statusCode;
  final String statusMessage;
  final Map<String, List<String>> headers;
  final MiniRequestOptions requestOptions;

  MiniResponse({
    this.data,
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.requestOptions,
  });
}
