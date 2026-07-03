import 'package:mini_server_annotations/mini_server_annotations.dart';
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
