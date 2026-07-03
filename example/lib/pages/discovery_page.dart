import 'package:flutter/material.dart';
import 'package:mini_server/mini_server.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

class DiscoveryScreen extends StatefulWidget {
  final MiniNode node;
  const DiscoveryScreen({super.key, required this.node});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  List<DiscoveredNode> _servers = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() => _searching = true);
    final results = await widget.node.discoverServers();
    setState(() {
      _servers = results;
      _searching = false;
    });
  }

  Future<void> _connect(DiscoveredNode target) async {
    final success = await widget.node.requestConnection(target, 'Cliente Visitante');
    if (success && mounted) {
       // Recarrega o provider principal com a nova conexão
       Provider.of<TodoProvider>(context, listen: false).refreshConnection();
       Navigator.pop(context); // Volta para a tela TodoScreen
    } else {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao conectar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descobrir Servidores'), actions: [
         IconButton(icon: const Icon(Icons.refresh), onPressed: _search)
      ]),
      body: _searching
        ? const Center(child: CircularProgressIndicator())
        : _servers.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Nenhum servidor encontrado na rede local."),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _search,
                      child: const Text("Buscar Novamente"),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _servers.length,
                itemBuilder: (context, index) {
                  final s = _servers[index];
                  return ListTile(
                    leading: const Icon(Icons.dns),
                    title: Text(s.name),
                    subtitle: Text('${s.ip}:${s.port}'),
                    onTap: () => _connect(s),
                  );
                },
              ),
    );
  }
}
