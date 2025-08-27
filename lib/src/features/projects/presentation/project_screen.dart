import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:orbit/src/features/create/presentation/create_project_task_screen.dart';
import 'package:orbit/src/features/projects/domain/project.dart';
import 'package:orbit/src/features/tasks/domain/task.dart';
import 'package:orbit/src/models/firestore_repository.dart';
import 'package:orbit/theme.dart';

class ProjectScreen extends StatefulWidget {
  final Project project;

  const ProjectScreen({
    super.key,
    required this.project
  });

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  late Project _project;                
  List<Task> taskList = [];

  @override
  void initState() {
    super.initState();
    _project = widget.project;          
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final db = FirestoreRepository();
    final loadedProject = await db.getProjectTasks(userId, _project.id);
    setState(() => taskList = loadedProject.tasks);
  }

Future<void> _openEditSheet() async {
  final result = await showModalBottomSheet<EditProject>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return _EditProjectSheet(project: _project); 
    },
  );

  if (result == null) return;

  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return;

  final repo = FirestoreRepository();

  if (result.delete) {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Delete Project', style: TextStyle(color: AppColors.white)),
        content: const Text('This will delete the project and its tasks.',
            style: TextStyle(color: AppColors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white),)),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await repo.deleteProject(userId, _project.id);
      if (mounted) Navigator.pop(context); // pop ProjectScreen
    }
    return;
  }

  // Save edits to Firestore
  final newTitle = result.title.trim();
  final newDesc  = result.description.trim();

  final updated = Project(
    id: _project.id,
    title: newTitle,
    description: newDesc.isEmpty ? null : newDesc,
    tasks: _project.tasks,
    ownerId: _project.ownerId,
    tag: _project.tag,
  );

  // After saving to Firestore
  await repo.updateProject(userId, updated);
  if (!mounted) return;
  setState(() => _project = updated);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Project updated')),
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: null,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openEditSheet,               
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _project.title,                    
                  style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Description:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 60,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _project.description ?? "",
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tasks header
                const Text(
                  "Tasks:",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                // Task list
                if (taskList.isEmpty)
                  const Center(
                    child: Text(
                      'No tasks yet',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  )
                else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: taskList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = taskList[index];
                    final priority = task.priority.name;
                    final borderColor = switch (task.priority) {
                      TaskPriority.low => Colors.green,
                      TaskPriority.medium => Colors.orange,
                      TaskPriority.high => Colors.red,
                    };

                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.black,
                            title: const Text("Delete Task", style: TextStyle(color: Colors.white)),
                            content: const Text("Are you sure you want to delete this task?", style: TextStyle(color: Colors.white70)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        return confirm == true;
                      },
                      onDismissed: (_) async {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId == null) return;

                        final taskId = taskList[index].id;

                        setState(() {
                          taskList.removeAt(index);
                        });

                        final repo = FirestoreRepository();
                        await repo.deleteProjectTask(userId, widget.project.id, taskId);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              priority,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Files section
                const Text(
                  "Files:",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1F1F1F),
                    borderRadius: BorderRadius.circular(12),
                    //TODO
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Add file tapped')),
                          );
                        },
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromRGBO(28, 125, 28, 1),
        foregroundColor: Colors.white,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateProjectTaskScreen(projectId: widget.project.id)),
          );
          if (result != null && result is Task) {
            setState(() {
              taskList.add(result);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditProject {
  final String title;
  final String description;
  final bool delete;
  EditProject({required this.title, required this.description, this.delete = false});
}

class _EditProjectSheet extends StatefulWidget {
  final Project project;
  const _EditProjectSheet({super.key, required this.project});

  @override
  State<_EditProjectSheet> createState() => _EditProjectSheetState();
}

class _EditProjectSheetState extends State<_EditProjectSheet> {
  late final TextEditingController titleCtrl;
  late final TextEditingController descCtrl;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.project.title);
    descCtrl  = TextEditingController(text: widget.project.description ?? '');
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final height = MediaQuery.of(context).size.height * 2 / 3; // 2/3 screen
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: AppDecorations.card.copyWith(
          color: AppColors.background,
          border: Border.all(
            color: AppColors.card,
            width: 1,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white54,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Edit project', style: AppTextStyles.title),
              const SizedBox(height: 12),

              // Title
              Container(
                decoration: AppDecorations.input,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: titleCtrl,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    hintStyle: AppTextStyles.hint,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Expanded(
                child: Container(
                  decoration: AppDecorations.input,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: TextField(
                    controller: descCtrl,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    style: AppTextStyles.body,
                    decoration: const InputDecoration(
                      hintText: 'Description',
                      hintStyle: AppTextStyles.hint,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save changes
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Title can’t be empty')),
                    );
                    return;
                  }
                  Navigator.pop(
                    context,
                    EditProject(
                      title: titleCtrl.text,
                      description: descCtrl.text,
                    ),
                  );
                },
                child: const Text('Save changes'),
              ),
              const SizedBox(height: 12),

              // Delete project
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.pop(
                    context,
                    EditProject(
                      title: titleCtrl.text,
                      description: descCtrl.text,
                      delete: true,
                    ),
                  );
                },
                child: const Text('Delete project'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}