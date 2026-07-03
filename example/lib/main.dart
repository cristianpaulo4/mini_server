import 'package:flutter/material.dart';
import 'package:mini_server/mini_server.dart';
import 'package:provider/provider.dart';
import 'repositories/todo_repository.dart';
import 'repositories/todo_repository_local.dart';
import 'providers/todo_provider.dart';
import 'pages/todo_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Instanciação ÚNICA do nó de rede e repositórios para todo o ciclo de vida do app
  final node = MiniNode(
    mode: NetworkMode.server, // Inicia como Servidor/Local por padrão
    friendlyName: 'Meu Dispositivo P2P',
    repositories: [
      TodoRepositoryProxy(localImpl: TodoRepositoryLocal()),
    ],
  );

  // Callback automático para conexões locais
  node.onConnectionRequest = (clientName) async {
     print("Acesso solicitado por: $clientName");
     return true; // Aceita conexões automaticamente no exemplo
  };

  // Inicia o servidor local de cara para atuar de forma standalone no SQLite
  await node.start();

  runApp(
    ChangeNotifierProvider(
      create: (_) => TodoProvider(repository: node.get<TodoRepository>(), node: node),
      child: MyApp(node: node),
    ),
  );
}

class MyApp extends StatelessWidget {
  final MiniNode node;
  const MyApp({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Server P2P',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const TodoScreen(),
    );
  }
}
