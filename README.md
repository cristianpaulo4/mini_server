# Mini Server P2P 🌐

O **Mini Server P2P** é um framework completo para transformar seu aplicativo Flutter em um nó de rede intranet P2P (estilo Axios HTTP). Ele permite que dispositivos na mesma rede Wi-Fi se descubram de forma automática, realizem pareamento seguro por token, façam operações CRUD e se sincronizem em tempo real via WebSockets.

Ele é ideal para cenários onde um dispositivo atua como banco de dados local (ex: rodando SQLite com `sqflite`) e outros dispositivos na mesma rede intranet se conectam a ele para ler e gravar dados diretamente, sem depender de servidores na nuvem (APIs externas).

---

## 🚀 Principais Recursos

- **Geração de Código (Proxy Pattern)**: Defina a interface do seu repositório com anotações e o `build_runner` gerará automaticamente a classe Proxy que desvia chamadas para o Banco Local (modo Servidor) ou chamadas de Rede (modo Cliente).
- **Descoberta Automática de Rede (UDP Beacon)**: O Servidor envia pings via sockets UDP e os clientes encontram o IP/Porta do servidor na rede local sem configurações manuais de IP.
- **Handshake e Pareamento**: Conexão baseada em tokens de autorização temporários após aceite da UI.
- **Sincronização em Tempo Real (WebSockets)**: Modificações feitas por qualquer cliente ou servidor disparam notificações WebSocket que forçam o recarregamento automático da UI em todos os dispositivos conectados.
- **Service Locator Unificado**: Registre e recupere todos os seus repositórios no `MiniNode` de forma simples usando uma lista dinâmica.

---

## 🛠️ Como Usar (Passo a Passo)

### 1. Dependências no `pubspec.yaml`

Adicione as dependências do ecossistema nos seus respectivos pacotes:

```yaml
dependencies:
  flutter:
    sdk: flutter
  mini_server: ^2.0.0
  provider: ^6.1.1 # Opcional para gerenciamento de estado

dev_dependencies:
  build_runner: ^2.4.6
```

---

### 2. Defina o Modelo e a Interface do Repositório

Defina o seu DTO (com funções `.toJson()` e `.fromJson()`) e a interface abstrata anotada com `@MiniRepository` e seus verbos:

```dart
// lib/models/todo.dart
class Todo {
  final int? id;
  final String title;
  final bool isDone;

  Todo({this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'isDone': isDone ? 1 : 0};

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
    id: json['id'],
    title: json['title'],
    isDone: json['isDone'] == 1 || json['isDone'] == true,
  );
}
```

```dart
// lib/repositories/todo_repository.dart
import 'package:mini_server/mini_server.dart';
import '../models/todo.dart';

part 'todo_repository.g.dart';

@MiniRepository('/todo')
abstract class TodoRepository {
  @Post('/create')
  Future<Todo> createTodo(Todo todo);

  @Get('/list')
  Future<List<Todo>> getTodos();

  @Put('/update')
  Future<Todo> updateTodo(Todo todo);

  @Delete('/delete')
  Future<void> deleteTodo(Todo todo);
}
```

Dispare a geração de código no terminal:
```bash
dart run build_runner build --delete-conflicting-outputs
```
O gerador compilará a classe `TodoRepositoryProxy` que implementa a interface e herda `MiniProxy`.

---

### 3. Implemente a Persistência Local (Apenas no Servidor)

Crie a implementação concreta do seu repositório (que salvará no SQLite/Sqflite, por exemplo):

```dart
// lib/repositories/todo_repository_local.dart
import '../models/todo.dart';
import 'todo_repository.dart';

class TodoRepositoryLocal implements TodoRepository {
  @override
  Future<Todo> createTodo(Todo todo) async {
    // Grava no banco e retorna o objeto com ID gerado
  }

  @override
  Future<List<Todo>> getTodos() async {
    // Lê todos os itens do banco de dados local
  }

  @override
  Future<Todo> updateTodo(Todo todo) async {
    // Atualiza o registro local
  }

  @override
  Future<void> deleteTodo(Todo todo) async {
    // Deleta o registro local
  }
}
```

---

### 4. Inicialize o `MiniNode` no Início do App

O nó deve ser inicializado uma única vez (no seu `main.dart`) passando a lista de proxies com suas devidas implementações locais (caso atue como servidor):

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:mini_server/mini_server.dart';
import 'repositories/todo_repository.dart';
import 'repositories/todo_repository_local.dart';

void main() {
  final node = MiniNode(
    mode: NetworkMode.client, // Inicia em modo cliente por padrão
    friendlyName: 'Dispositivo P2P',
    repositories: [
      TodoRepositoryProxy(localImpl: TodoRepositoryLocal()),
    ],
  );

  runApp(MyApp(node: node));
}
```

---

### 5. Controle o Modo Dinamicamente nas Telas

O `MiniNode` permite alternar entre servidor e cliente em tempo de execução.

#### Ativando o Modo Servidor:
Quando o usuário decidir que o dispositivo atual será o hospedeiro (Servidor):
```dart
// Em seu Provider ou Controller
Future<void> setServerMode() async {
  node.mode = NetworkMode.server;
  node.onConnectionRequest = (clientName) async {
    print("Acesso solicitado por: $clientName");
    return true; // Retorne true para aceitar a conexão
  };
  await node.start(); // Inicia o broadcast UDP e o servidor WebSocket
}
```

#### Buscando e Conectando como Cliente:
Para clientes, você pode realizar uma varredura na rede local e conectar a um servidor descoberto:
```dart
// 1. Defina o modo para cliente
await node.stop(); // Para o servidor local, se estiver rodando
node.mode = NetworkMode.client;

// 2. Busque servidores na Intranet (retorna List<DiscoveredNode>)
List<DiscoveredNode> servers = await node.discoverServers();

// 3. Solicite conexão ao servidor desejado
if (servers.isNotEmpty) {
  bool success = await node.requestConnection(servers.first, 'Nome do Cliente');
  if (success) {
    print('Conectado com sucesso ao servidor: ${servers.first.name}');
  } else {
    print('Falha ao conectar ou conexão recusada.');
  }
}
```

---

### 6. Consuma o Repositório de Forma Abstraída

Nos seus Providers/ChangeNotifiers ou nas telas, basta resgatar o repositório diretamente do `MiniNode`. O nó se encarregará de buscar o Proxy correto. O provedor de estados também pode escutar o `node.eventStream` para atualizações de rede automáticas:

```dart
class TodoProvider extends ChangeNotifier {
  final TodoRepository repository;
  final MiniNode node;
  List<Todo> todos = [];
  StreamSubscription? _sub;

  TodoProvider({required this.node}) : repository = node.get<TodoRepository>() {
    _load();
    // Escuta atualizações automáticas via WebSocket
    _sub = node.eventStream.listen((event) {
      if (event == "/todo") {
        _load();
      }
    });
  }

  Future<void> _load() async {
    todos = await repository.getTodos();
    notifyListeners();
  }

  Future<void> add(String title) async {
    await repository.createTodo(Todo(title: title));
    // As rotas mutantes já disparam node.broadcastEvent automaticamente!
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```
