import 'package:flutter/material.dart';
import 'package:mini_server/mini_server.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import 'discovery_page.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  void _showAddDialog(BuildContext context, TodoProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Tarefa'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nome da tarefa'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addTodo(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context, TodoProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final isServer = provider.node.mode == NetworkMode.server;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Configurações P2P", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Nome do aparelho: ${provider.node.friendlyName}"),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text("Modo Servidor (Local)"),
                subtitle: const Text("Hospeda o banco localmente e aceita conexões de outros aparelhos"),
                value: isServer,
                onChanged: (val) async {
                  Navigator.pop(ctx);
                  if (val) {
                    await provider.setServerMode();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Modo Servidor ativo! Servidor aberto na rede.')),
                    );
                  } else {
                    await provider.setClientMode();
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DiscoveryScreen(node: provider.node)),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TodoProvider>();
    final isServer = provider.node.mode == NetworkMode.server;
    final isClient = provider.node.mode == NetworkMode.client;
    final baseUrl = provider.node.client.options.baseUrl;
    final isConnectedClient = isClient && baseUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isServer ? 'Servidor Todo List' : 'Cliente Conectado'),
        backgroundColor: isServer ? Colors.green : Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSettings(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isClient && !isConnectedClient)
            Container(
              color: Colors.orange.shade100,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Aparelho em modo cliente (Desconectado). Conecte-se a um servidor.",
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DiscoveryScreen(node: provider.node)),
                      );
                    },
                    child: const Text("Conectar"),
                  ),
                ],
              ),
            ),
          if (isClient && isConnectedClient)
            Container(
              color: Colors.blue.shade50,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Conectado ao Servidor: $baseUrl",
                style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w500, fontSize: 12),
              ),
            ),
          Expanded(
            child: provider.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : provider.todos.isEmpty
                ? const Center(child: Text("Nenhuma tarefa cadastrada."))
                : ListView.builder(
                    itemCount: provider.todos.length,
                    itemBuilder: (context, index) {
                      final t = provider.todos[index];
                      return ListTile(
                        title: Text(
                          t.title,
                          style: TextStyle(
                            decoration: t.isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        leading: Checkbox(
                          value: t.isDone, 
                          onChanged: (_) => provider.toggleDone(t),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => provider.deleteTodo(t),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, provider),
        child: const Icon(Icons.add),
      ),
    );
  }
}
