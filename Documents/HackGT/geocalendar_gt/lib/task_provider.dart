import 'package:flutter/foundation.dart';
import '../models/task.dart';

class TaskProvider extends ChangeNotifier {
  final List<Task> _tasks = [];

  List<Task> get tasks => List.unmodifiable(_tasks);

  void addTask(Task t) {
    _tasks.add(t);
    notifyListeners();
  }

  void clear() {
    _tasks.clear();
    notifyListeners();
  }
}
