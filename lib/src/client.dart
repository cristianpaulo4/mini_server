import 'dart:convert';
import 'dart:io';

import 'options.dart';
import 'response.dart';
import 'error.dart';
import 'interceptors.dart';

class MiniClient {
  MiniRequestOptions options;
  final List<Interceptor> interceptors = [];

  MiniClient({MiniRequestOptions? options}) 
      : options = options ?? MiniRequestOptions();

  Future<MiniResponse<T>> get<T>(String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return request<T>(path, method: 'GET', queryParameters: queryParameters, headers: headers);
  }

  Future<MiniResponse<T>> post<T>(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return request<T>(path, method: 'POST', data: data, queryParameters: queryParameters, headers: headers);
  }

  Future<MiniResponse<T>> put<T>(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return request<T>(path, method: 'PUT', data: data, queryParameters: queryParameters, headers: headers);
  }

  Future<MiniResponse<T>> delete<T>(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return request<T>(path, method: 'DELETE', data: data, queryParameters: queryParameters, headers: headers);
  }

  Future<MiniResponse<T>> request<T>(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    // 1. Prepare options
    var requestOptions = options.copyWith(
      headers: {...options.headers, ...?headers},
    );

    // 2. Run request interceptors
    for (var interceptor in interceptors) {
      requestOptions = await interceptor.onRequest(requestOptions);
    }

    // 3. Build URL
    var uri = Uri.parse('${requestOptions.baseUrl}$path');
    if (queryParameters != null) {
      uri = uri.replace(queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())));
    }

    try {
      // 4. Make HTTP request
      var client = HttpClient();
      if (requestOptions.timeout != null) {
        client.connectionTimeout = requestOptions.timeout;
      }

      var req = await client.openUrl(method, uri);

      // Add headers
      requestOptions.headers.forEach((key, value) {
        req.headers.set(key, value.toString());
      });

      // Add body
      if (data != null) {
        if (data is Map || data is List) {
          req.headers.contentType = ContentType.json;
          req.write(jsonEncode(data));
        } else {
          req.write(data.toString());
        }
      }

      var res = await req.close();
      var responseBody = await res.transform(utf8.decoder).join();
      
      dynamic responseData = responseBody;
      try {
        if (responseBody.isNotEmpty) {
           responseData = jsonDecode(responseBody);
        }
      } catch (e) {
        // Not JSON
      }

      var responseHeaders = <String, List<String>>{};
      res.headers.forEach((name, values) {
        responseHeaders[name] = values;
      });

      var miniResponse = MiniResponse<T>(
        data: responseData as T?,
        statusCode: res.statusCode,
        statusMessage: res.reasonPhrase,
        headers: responseHeaders,
        requestOptions: requestOptions,
      );

      // 5. Check status code
      if (res.statusCode >= 200 && res.statusCode < 300) {
        // Run response interceptors
        for (var interceptor in interceptors) {
          miniResponse = await interceptor.onResponse(miniResponse) as MiniResponse<T>;
        }
        return miniResponse;
      } else {
        throw MiniError(
          requestOptions: requestOptions,
          response: miniResponse,
          type: MiniErrorType.response,
          message: 'Http status error [${res.statusCode}]',
        );
      }
    } catch (e) {
      if (e is MiniError) {
        return _handleError(e);
      }
      var error = MiniError(
        requestOptions: requestOptions,
        type: MiniErrorType.other,
        error: e,
        message: e.toString(),
      );
      return _handleError(error);
    }
  }

  Future<MiniResponse<T>> _handleError<T>(MiniError error) async {
    for (var interceptor in interceptors) {
      try {
        await interceptor.onError(error);
      } catch (e) {
        if (e is MiniError) error = e;
      }
    }
    throw error;
  }
}
