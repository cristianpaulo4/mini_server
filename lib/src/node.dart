import 'dart:async';
import 'dart:io';
import 'client.dart';
import 'server.dart';
import 'options.dart';
import 'discovery.dart';
import 'proxy.dart';

enum NetworkMode { server, client }

class MiniNode {
  NetworkMode mode;
  final String friendlyName;
  final int serverPort;

  late final MiniClient client;
  late final MiniServer server;
  late final NetworkDiscovery _discovery;

  String? _sessionToken;
  WebSocket? _clientSocket;
  final _eventController = StreamController<String>.broadcast();
  Stream<String> get eventStream => _eventController.stream;

  // Callback para a UI aprovar conexões
  Future<bool> Function(String clientName)? onConnectionRequest;

  // Registro de repositórios (Service Locator interno)
  final Map<Type, dynamic> _registry = {};

  void register<T>(T instance) {
    _registry[T] = instance;
  }

  T get<T>() {
    final instance = _registry[T];
    if (instance == null) {
      throw Exception("Repositório do tipo $T não foi registrado no MiniNode.");
    }
    return instance as T;
  }

  MiniNode({
    required this.mode,
    this.friendlyName = 'Meu Dispositivo',
    this.serverPort = 8080,
    List<MiniProxy> repositories = const [],
  }) {
    client = MiniClient(
        options: MiniRequestOptions(timeout: const Duration(seconds: 10)));
    server = MiniServer(port: serverPort);
    _discovery = NetworkDiscovery();
    
    // Inicializa e registra todos os repositórios passados
    for (var repo in repositories) {
       repo.node = this;
       repo.registerRoutes();
       _registry[repo.interfaceType] = repo;
    }

    // Handshake Endpoint (Apenas no servidor)
    server.registerRoute('POST', '/mini_node/connect', (data) async {
      if (onConnectionRequest == null)
        return {'accepted': true, 'token': 'token_padrao_123'};

      String clientName = data?['name'] ?? 'Desconhecido';
      bool accepted = await onConnectionRequest!(clientName);

      if (accepted) {
        return {'accepted': true, 'token': 'token_aprovado_123'};
      } else {
        return {'accepted': false};
      }
    });
  }

  void _connectWebSocket(String ip, int port) async {
    try {
      final wsUrl = 'ws://$ip:$port/mini_node/ws';
      _clientSocket = await WebSocket.connect(wsUrl);
      _clientSocket!.listen((message) {
        _eventController.add(message.toString());
      }, onDone: () {
        _clientSocket = null;
      }, onError: (_) {
        _clientSocket = null;
      });
    } catch (e) {
      print("Erro ao conectar no WebSocket: $e");
    }
  }

  void broadcastEvent(String event) {
    if (mode == NetworkMode.server) {
      server.broadcast(event);
    }
    _eventController.add(event);
  }

  Future<void> start() async {
    if (mode == NetworkMode.server) {
      await server.start();
      await _discovery.startBroadcasting(friendlyName, serverPort);
    }
  }

  Future<void> stop() async {
    await server.stop();
    _discovery.stopBroadcasting();
    await _clientSocket?.close();
    _clientSocket = null;
  }

  Future<List<DiscoveredNode>> discoverServers() async {
    return await _discovery.discoverServers();
  }

  Future<bool> requestConnection(DiscoveredNode target, String myName) async {
    client.options.baseUrl = 'http://${target.ip}:${target.port}';
    try {
      var response =
          await client.post('/mini_node/connect', data: {'name': myName});
      if (response.data != null && response.data['accepted'] == true) {
        _sessionToken = response.data['token'];
        client.options.headers['Authorization'] = 'Bearer $_sessionToken';

        // Conecta ao canal de eventos WebSocket
        _connectWebSocket(target.ip, target.port);

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
