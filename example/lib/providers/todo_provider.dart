import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mini_server/mini_server.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

class TodoProvider extends ChangeNotifier {
  final TodoRepository repository;
  final MiniNode node;
  List<Todo> _todos = [];
  bool _loading = false;
  StreamSubscription? _eventSubscription;

  TodoProvider({required this.repository, required this.node}) {
    _load();
    // Escuta eventos de atualização da rede e recarrega os dados em tempo real
    _eventSubscription = node.eventStream.listen((event) {
      if (event == "/todo") {
        _load();
      }
    });
  }

  List<Todo> get todos => _todos;
  bool get isLoading => _loading;

  Future<void> _load() async {
    _loading = true;
    notifyListeners();
    try {
      _todos = await repository.getTodos();
    } catch (e) {
      print("Erro ao carregar: $e");
      _todos = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setServerMode() async {
    node.mode = NetworkMode.server;
    node.onConnectionRequest = (clientName) async => true;
    await node.start();
    notifyListeners();
    await _load();
  }

  Future<void> setClientMode() async {
    await node.stop();
    node.mode = NetworkMode.client;
    notifyListeners();
    await _load();
  }

  Future<void> refreshConnection() async {
    notifyListeners();
    await _load();
  }

  Future<void> addTodo(String title) async {
    try {
      await repository.createTodo(Todo(title: title));
    } catch (e) {
      print("Erro ao criar: $e");
    }
  }

  Future<void> toggleDone(Todo todo) async {
    try {
      final updated = Todo(id: todo.id, title: todo.title, isDone: !todo.isDone);
      await repository.updateTodo(updated);
    } catch (e) {
      print("Erro ao atualizar: $e");
    }
  }

  Future<void> deleteTodo(Todo todo) async {
    try {
      await repository.deleteTodo(todo);
    } catch (e) {
      print("Erro ao deletar: $e");
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
