import 'options.dart';
import 'response.dart';

enum MiniErrorType {
  connectTimeout,
  sendTimeout,
  receiveTimeout,
  response,
  cancel,
  other,
}

class MiniError implements Exception {
  final MiniRequestOptions requestOptions;
  final MiniResponse? response;
  final MiniErrorType type;
  final dynamic error;
  final String? message;

  MiniError({
    required this.requestOptions,
    this.response,
    this.type = MiniErrorType.other,
    this.error,
    this.message,
  });

  @override
  String toString() {
    var msg = 'MiniError [${type.toString().split('.').last}]: $message';
    if (error != null) {
      msg += '\nSource: $error';
    }
    return msg;
  }
}
