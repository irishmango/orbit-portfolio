import 'package:flutter/material.dart';
import 'package:orbit/src/features/projects/domain/project.dart';
import 'package:orbit/src/features/tasks/domain/task.dart';


class TaskProjectProvider extends ChangeNotifier {
  List<Project> _projects = [];
  List<Task> _tasks = [];

  List<Project> get projects => _projects;
  List<Task> get tasks => _tasks;

  void setProjects(List<Project> projects) {
    _projects = projects;
    notifyListeners();
  }

  void setTasks(List<Task> tasks) {
    _tasks = tasks;
    notifyListeners();
  }
}
