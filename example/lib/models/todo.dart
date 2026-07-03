class Todo {
  final int? id;
  final String title;
  final bool isDone;

  Todo({this.id, required this.title, this.isDone = false});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone ? 1 : 0,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      isDone: json['isDone'] == 1 || json['isDone'] == true,
    );
  }
}
