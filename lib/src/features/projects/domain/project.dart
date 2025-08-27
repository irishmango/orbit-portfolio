import 'package:orbit/src/features/tasks/domain/task.dart';

class Project {
  final String id;
  final String title;
  final String? description;
  final List<Task> tasks;
  final String ownerId; 
  final String tag;     

  Project({
    required this.id,
    required this.title,
    this.description,
    required this.tasks,
    required this.ownerId,
    this.tag = "Project",
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'ownerId': ownerId,
      'tag': tag,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      tasks: (map['tasks'] as List? ?? const [])
          .map((taskMap) => Task.fromMap(Map<String, dynamic>.from(taskMap)))
          .toList(),
      ownerId: map['ownerId'],
      tag: map['tag'] ?? 'Project',
    );
  }
}