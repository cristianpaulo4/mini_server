import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DiscoveredNode {
  final String name;
  final String ip;
  final int port;
  DiscoveredNode(this.name, this.ip, this.port);
}

class NetworkDiscovery {
  static const int _broadcastPort = 8888;
  static const String _magicString = "MINISERVER_BEACON";

  RawDatagramSocket? _socket;
  Timer? _beaconTimer;

  // Broadcasts presence to the network
  Future<void> startBroadcasting(String friendlyName, int httpPort) async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
    _socket!.broadcastEnabled = true;

    _beaconTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final message = '$_magicString|$friendlyName|$httpPort';
      _socket!.send(utf8.encode(message), InternetAddress("255.255.255.255"), _broadcastPort);
    });
  }

  void stopBroadcasting() {
    _beaconTimer?.cancel();
    _socket?.close();
  }

  // Listens for broadcasts to find servers
  Future<List<DiscoveredNode>> discoverServers({Duration timeout = const Duration(seconds: 3)}) async {
    var socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _broadcastPort);
    socket.broadcastEnabled = true;
    
    // Obter IPs locais para ignorar a si mesmo
    var interfaces = await NetworkInterface.list();
    var myIps = interfaces.expand((i) => i.addresses).map((a) => a.address).toSet();

    Map<String, DiscoveredNode> found = {};
    
    socket.listen((RawSocketEvent e) {
      if (e == RawSocketEvent.read) {
        Datagram? d = socket.receive();
        if (d != null) {
          String message = utf8.decode(d.data);
          if (message.startsWith(_magicString)) {
             var parts = message.split('|');
             if (parts.length == 3) {
                var name = parts[1];
                var port = int.tryParse(parts[2]) ?? 8080;
                var ip = d.address.address;
                
                // Ignora pacotes vindos do próprio dispositivo
                if (!myIps.contains(ip)) {
                   found[ip] = DiscoveredNode(name, ip, port);
                }
             }
          }
        }
      }
    });

    await Future.delayed(timeout);
    socket.close();
    return found.values.toList();
  }
}
