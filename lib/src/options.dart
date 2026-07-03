class MiniRequestOptions {
  String baseUrl;
  Map<String, dynamic> headers;
  Duration? timeout;
  
  MiniRequestOptions({
    this.baseUrl = '',
    Map<String, dynamic>? headers,
    this.timeout,
  }) : headers = headers ?? {};

  MiniRequestOptions copyWith({
    String? baseUrl,
    Map<String, dynamic>? headers,
    Duration? timeout,
  }) {
    return MiniRequestOptions(
      baseUrl: baseUrl ?? this.baseUrl,
      headers: headers ?? this.headers,
      timeout: timeout ?? this.timeout,
    );
  }
}
