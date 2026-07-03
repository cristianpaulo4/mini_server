// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_repository.dart';

// **************************************************************************
// MiniRepositoryGenerator
// **************************************************************************

// ignore_for_file: prefer_function_declarations_over_variables
class TodoRepositoryProxy implements TodoRepository, MiniProxy {
  @override
  late MiniNode node;
  final TodoRepository? localImpl;

  @override
  Type get interfaceType => TodoRepository;

  TodoRepositoryProxy({this.localImpl});

  @override
  void registerRoutes() {
    if (localImpl != null) {
      node.server.registerRoute("POST", "/todo/create",
          (dynamic requestData) async {
        var param = Todo.fromJson(requestData as Map<String, dynamic>);
        var result = await localImpl!.createTodo(param);
        node.broadcastEvent("/todo");
        // O Servidor enviará o toJson() do resultado de volta para o cliente
        return result;
      });
      node.server.registerRoute("GET", "/todo/list",
          (dynamic requestData) async {
        var result = await localImpl!.getTodos();
        // O Servidor enviará o toJson() do resultado de volta para o cliente
        return result;
      });
      node.server.registerRoute("PUT", "/todo/update",
          (dynamic requestData) async {
        var param = Todo.fromJson(requestData as Map<String, dynamic>);
        var result = await localImpl!.updateTodo(param);
        node.broadcastEvent("/todo");
        // O Servidor enviará o toJson() do resultado de volta para o cliente
        return result;
      });
      node.server.registerRoute("DELETE", "/todo/delete",
          (dynamic requestData) async {
        var param = Todo.fromJson(requestData as Map<String, dynamic>);
        var result = await localImpl!.deleteTodo(param);
        node.broadcastEvent("/todo");
        // O Servidor enviará o toJson() do resultado de volta para o cliente
        return result;
      });
    }
  }

  @override
  Future<Todo> createTodo(Todo todo) async {
    if (node.mode == NetworkMode.server) {
      var result = await localImpl!.createTodo(todo);
      node.broadcastEvent("/todo");
      return result;
    } else {
      // Modo Cliente: Dispara via Rede
      var response = await node.client.post(
        "/todo/create",
        data: todo.toJson(),
      );
      // Retorna objeto convertido
      return Todo.fromJson(response.data as Map<String, dynamic>);
    }
  }

  @override
  Future<List<Todo>> getTodos() async {
    if (node.mode == NetworkMode.server) {
      return await localImpl!.getTodos();
    } else {
      // Modo Cliente: Dispara via Rede
      var response = await node.client.get("/todo/list");
      // Retorna objeto convertido
      if (response.data is List) {
        return (response.data as List)
            .map((i) => Todo.fromJson(i as Map<String, dynamic>))
            .toList() as dynamic;
      }
      return [];
    }
  }

  @override
  Future<Todo> updateTodo(Todo todo) async {
    if (node.mode == NetworkMode.server) {
      var result = await localImpl!.updateTodo(todo);
      node.broadcastEvent("/todo");
      return result;
    } else {
      // Modo Cliente: Dispara via Rede
      var response = await node.client.put(
        "/todo/update",
        data: todo.toJson(),
      );
      // Retorna objeto convertido
      return Todo.fromJson(response.data as Map<String, dynamic>);
    }
  }

  @override
  Future<void> deleteTodo(Todo todo) async {
    if (node.mode == NetworkMode.server) {
      var result = await localImpl!.deleteTodo(todo);
      node.broadcastEvent("/todo");
      return result;
    } else {
      // Modo Cliente: Dispara via Rede
      await node.client.delete(
        "/todo/delete",
        data: todo.toJson(),
      );
      return;
    }
  }
}
