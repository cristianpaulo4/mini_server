import 'dart:convert';
import 'dart:io';

class MiniResponse {
  Map<String, dynamic>? body;
  Map<String, dynamic>?  parameters;

  MiniResponse({
    this.body,
    this.parameters,
  });

  Future<MiniResponse> init(HttpRequest httpRequest) async {
    String content = await utf8.decoder.bind(httpRequest).join();
    Map<String, dynamic> data =
        await jsonDecode(content) as Map<String, dynamic>;

    parameters = httpRequest.uri.queryParameters;

    return MiniResponse(body: data, parameters: parameters);
  }
}
