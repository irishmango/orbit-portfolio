import 'package:flutter/material.dart';
import 'package:orbit/src/features/projects/domain/project.dart';
import 'package:orbit/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orbit/src/features/tasks/domain/task.dart';

class ProjectCard extends StatefulWidget {
  final Project project;

  const ProjectCard({
    super.key,
    required this.project,
  });

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  List<Task> _tasks = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPreviewTasks();
  }

  @override
  void didUpdateWidget(covariant ProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadPreviewTasks(); // refresh preview tasks on rebuild
  }

  Future<void> _loadPreviewTasks() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('projects')
          .doc(widget.project.id)
          .collection('projectTasks')
          .limit(3) // only show 3 tasks
          .get();

      final tasks = snapshot.docs.map((d) => Task.fromMap(d.data())).toList();

      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tasks = [];
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> lines = (_loaded && _tasks.isNotEmpty)
        ? _tasks.map((t) => t.title).toList()
        : ['No tasks yet'];

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card.copyWith(
          border: Border.all(
            color: const Color.fromARGB(255, 86, 77, 77),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                widget.project.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Column(
              children: lines
                  .map((text) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("• ", style: TextStyle(color: Colors.grey[300])),
                            Expanded(
                              child: Text(
                                text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
