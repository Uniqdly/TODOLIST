import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TODO',
      debugShowCheckedModeBanner: false,
      home: TodoListScreen(),
    );
  }
}

class Todo {
  String title;
  String description;
  bool isCompleted;

  Todo({
    required this.title,
    required this.description,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
    };
  }

  static Todo fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      description: json['description'],
      isCompleted: json['isCompleted'],
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  List<Todo> _todos = [];
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadTodos(); // Загрузка задач при инициализации экрана
  }

  // Загружает задачи из SharedPreferences
  void _loadTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? todosJson = prefs.getStringList('todos');
    if (todosJson != null) {
      setState(() {
        _todos = todosJson
            .map((todoString) => Todo.fromJson(json.decode(todoString)))
            .toList();
      });
    }
  }

  // Сохраняет задачи в SharedPreferences
  void _saveTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> todosJson = _todos.map((todo) => json.encode(todo.toJson())).toList();
    await prefs.setStringList('todos', todosJson);
  }

  void _addOrEditTodo({Todo? todo, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTodoScreen(todo: todo),
      ),
    );
    if (result != null) {
      setState(() {
        if (index != null) {
          _todos[index] = result;
        } else {
          _todos.add(result);
        }
        _saveTodos(); // Сохранение после добавления или редактирования задачи
      });
    }
  }

  void _toggleCompleted(int index) {
    setState(() {
      _todos[index].isCompleted = !_todos[index].isCompleted;
      _saveTodos(); // Сохранение после переключения статуса выполнения
    });
  }

  void _deleteTodoAtIndex(int index) {
    setState(() {
      _todos.removeAt(index);
      _saveTodos(); // Сохранение после удаления задачи
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Todo> filteredTodos = _todos
        .where((todo) => _showCompleted ? todo.isCompleted : !todo.isCompleted)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_showCompleted ? "Выполненные задачи" : "Входящие задачи"),
        actions: [
          Switch(
            value: _showCompleted,
            onChanged: (value) {
              setState(() {
                _showCompleted = value;
              });
            },
          ),
        ],
      ),
      body: filteredTodos.isEmpty
          ? Center(child: Text("Нет задач"))
          : ListView.builder(
              itemCount: filteredTodos.length,
              itemBuilder: (context, index) {
                final todo = filteredTodos[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 18,
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(todo.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _addOrEditTodo(
                            todo: todo,
                            index: _todos.indexOf(todo),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () => _toggleCompleted(_todos.indexOf(todo)),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteTodoAtIndex(_todos.indexOf(todo)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditTodo(),
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddEditTodoScreen extends StatefulWidget {
  final Todo? todo;

  AddEditTodoScreen({this.todo});

  @override
  _AddEditTodoScreenState createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo == null ? "Добавить задачу" : "Сохранить задачу"),
        actions: widget.todo != null
            ? [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    Navigator.pop(context, null);
                  },
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Описание'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newTodo = Todo(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  isCompleted: widget.todo?.isCompleted ?? false,
                );
                Navigator.pop(context, newTodo);
              },
              child: Text(widget.todo == null ? "Добавить задачу" : "Сохранить задачу"),
            ),
          ],
        ),
      ),
    );
  }
}
