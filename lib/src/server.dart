import 'dart:convert';
import 'dart:io';

class MiniServer {
  final int port;
  HttpServer? _httpServer;
  final List<WebSocket> _sockets = [];

  final Map<String, Map<String, Function>> _routes = {
    'GET': {},
    'POST': {},
    'PUT': {},
    'DELETE': {},
  };

  MiniServer({required this.port});

  void registerRoute(String verb, String path, Function(dynamic) handler) {
    if (!_routes.containsKey(verb)) {
      _routes[verb] = {};
    }
    _routes[verb]![path] = handler;
  }

  void broadcast(String message) {
    for (var socket in _sockets) {
      try {
        socket.add(message);
      } catch (_) {}
    }
  }

  Future<void> start() async {
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    print('MiniServer escutando na porta $port');

    _httpServer!.listen((HttpRequest request) async {
      try {
        if (request.uri.path == '/mini_node/ws') {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            var socket = await WebSocketTransformer.upgrade(request);
            _sockets.add(socket);
            socket.listen(
              (msg) {},
              onDone: () => _sockets.remove(socket),
              onError: (err) => _sockets.remove(socket),
            );
            return;
          }
        }
        await _handleRequest(request);
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write(jsonEncode({'error': e.toString()}));
        await request.response.close();
      }
    });
  }

  Future<void> _handleRequest(HttpRequest request) async {
    var verb = request.method;
    var path = request.uri.path;
    var response = request.response;
    
    // Add CORS headers
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', 'Origin, Content-Type, Authorization');

    if (verb == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }

    if (_routes[verb] != null && _routes[verb]!.containsKey(path)) {
       var handler = _routes[verb]![path]!;
       
       dynamic bodyData;
       if (verb == 'POST' || verb == 'PUT' || verb == 'DELETE') {
         String content = await utf8.decoder.bind(request).join();
         if (content.isNotEmpty) {
            bodyData = jsonDecode(content);
         }
       }

       var result = await handler(bodyData);
       
       response.statusCode = HttpStatus.ok;
       response.headers.contentType = ContentType.json;
       
       if (result != null) {
          response.write(jsonEncode(result));
       } else {
          response.write(jsonEncode({'status': 'ok'}));
       }
    } else {
       response.statusCode = HttpStatus.notFound;
       response.write(jsonEncode({'error': 'Rota nao encontrada: $path'}));
    }
    
    await response.close();
  }

  Future<void> stop() async {
    for (var socket in _sockets) {
      await socket.close();
    }
    _sockets.clear();
    await _httpServer?.close(force: true);
  }
}
