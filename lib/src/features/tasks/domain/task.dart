enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String description;
  final TaskPriority priority;
  final bool isDone;
  final String? tag;
  final String projectId;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.isDone,
    this.tag,
    required this.projectId,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: TaskPriority.values.byName(map['priority']),
      isDone: map['isDone'] ?? false,
      tag: map['tag'] ?? '',
      projectId: map['projectId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name.toString(),
      'isDone': isDone,
      'tag': tag,
      'projectId': projectId,
    };
  }
}