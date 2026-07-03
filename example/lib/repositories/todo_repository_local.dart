import '../models/todo.dart';
import '../database/db_helper.dart';
import 'todo_repository.dart';

class TodoRepositoryLocal implements TodoRepository {
  @override
  Future<Todo> createTodo(Todo todo) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('todos', todo.toJson());
    return Todo(id: id, title: todo.title, isDone: todo.isDone);
  }

  @override
  Future<List<Todo>> getTodos() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('todos', orderBy: 'id DESC');
    return result.map((json) => Todo.fromJson(json)).toList();
  }

  @override
  Future<Todo> updateTodo(Todo todo) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'todos',
      todo.toJson(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
    return todo;
  }

  @override
  Future<void> deleteTodo(Todo todo) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }
}
