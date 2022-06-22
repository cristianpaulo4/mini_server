import 'dart:convert';
import 'dart:io';

class MiniResponse {
  MiniResponse._();
  static final MiniResponse _instance = MiniResponse._();
  static MiniResponse get instance => _instance;

  static  Map<String, dynamic>? _body;
  static  Map<String, dynamic>? _parameters;

  Map<String, dynamic>? get body => _body;  
  Map<String, dynamic>? get parameters => _parameters;  

  factory MiniResponse({
    required Map<String, dynamic>? body,
    required Map<String, dynamic>? parameters,
  }) {
    _body = body;
    _parameters = parameters;
    return instance;
  }

  Future<MiniResponse> init(HttpRequest httpRequest) async {
    String content = await utf8.decoder.bind(httpRequest).join();
    Map<String, dynamic> data =
        await jsonDecode(content) as Map<String, dynamic>;

    _parameters = httpRequest.uri.queryParameters;

    return MiniResponse(body: data, parameters: _parameters);
  }
}
