import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:orbit/src/features/auth/domain/AppUser.dart';
import 'package:orbit/src/features/collaborations/domain/collaboration.dart';
import 'package:orbit/src/features/tasks/domain/task.dart';
import 'package:orbit/src/models/firestore_repository.dart';
import 'package:orbit/src/features/projects/domain/project.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int descriptionLength = 0;
  final List<String> assignedUsers = [''];
  String _selectedTag = 'Personal';
  Color tagColor = Colors.red;
  String _selectedPriority = 'High';
  final List<String> priorityOptions = ['High', 'Medium', 'Low'];

  String createType = 'Personal';
  final List<String> createOptions = [
    'Personal',
    'Project',
    'Collaboration',
  ];

  String getButtonLabel() {
    switch (createType) {
      case 'Collaboration':
        return 'Create Collaboration';
      case 'Project':
        return 'Create Project';
      case 'Personal':
      default:
        return 'Create Task';
    }
  }

  @override
  void initState() {
    super.initState();
    final current = FirebaseAuth.instance.currentUser;
    final label = (current?.displayName?.trim().isNotEmpty == true)
        ? current!.displayName!.trim()
        : (current?.email?.trim().isNotEmpty == true)
            ? current!.email!.trim()
            : current?.uid ?? '';

    assignedUsers
      ..clear()
      ..add(label);
  }

  Future<void> createItem() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      if (createType == "Project") {
        // new project creation
        final project = Project(
          id: '', 
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          tasks: [],
          ownerId: userId,
          tag: _selectedTag,
        );
        final repo = FirestoreRepository();
        await repo.createProject(userId, project);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // TODO: add check
            content: Text('Project successfully created!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _descriptionController.clear();
        Navigator.of(context).pop(project);

      } else if (createType == "Personal") {
        // new task creation
        final repo = FirestoreRepository();
        final taskId = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('personalTasks')
            .doc()
            .id;

        final task = Task(
          id: taskId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: TaskPriority.values.byName(_selectedPriority.toLowerCase()),
          isDone: false,
          tag: _selectedTag,
          projectId: '',
        );

        await repo.createPersonalTask(userId, task);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task successfully created!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _descriptionController.clear();
        Navigator.of(context).pop(task);

      } else if (createType == "Collaboration") {
        final currentUser = FirebaseAuth.instance.currentUser!;
        final creator = AppUser.fromFirebaseUser(currentUser);

        // For now we only have the creator reliably; add a real picker later.
        final members = <AppUser>[creator];
        final memberIds = <String>[creator.id];

        final draft = Collaboration(
          id: '', // repo will assign
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          members: members,      // objects for UI
          memberIds: memberIds,  // strings for queries
          creatorId: creator.id,
        );

        final repo = FirestoreRepository();
        final created = await repo.createCollaboration(creator, draft);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collaboration successfully created!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );

        _titleController.clear();
        _descriptionController.clear();
        Navigator.of(context).pop(created); 
      }
    } catch (e) {
      debugPrint('Error creating task/project/collaboration: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Create", style: TextStyle(fontSize: 34),),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F1F1F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: createType,
                        dropdownColor: const Color(0xFF2A2A2A),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        style: const TextStyle(color: Colors.white),
                        items: createOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            createType = newValue!;
                            _selectedTag = createType;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Project Title Input
              if (createType == "Project")
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _titleController,
                  cursorColor: Color.fromRGBO(28, 125, 28, 1),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Project Title',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),

              // Title Input
              if (createType == "Personal")
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),


              // Collaboration Title Input
              if (createType == "Collaboration")
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _titleController,
                  cursorColor: Color.fromRGBO(28, 125, 28, 1),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(
                    hintText: 'Collaboration Title',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Description Input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _descriptionController,
                      cursorColor: Color.fromRGBO(28, 125, 28, 1),
                      maxLines: 5,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (text) {
                        setState(() {
                          descriptionLength = text.length;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Description',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Text(
                        '$descriptionLength/300',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Assignee section
              if (createType == "Collaboration")
              AssignWidget(assignedUsers: assignedUsers),
              

              // Tag selection
              if (createType == "Personal") 
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2<String>(
                          isExpanded: true,
                          value: _selectedPriority,
                          dropdownStyleData: DropdownStyleData(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            maxHeight: 150,
                          ),
                          buttonStyleData: ButtonStyleData(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1F1F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          iconStyleData: const IconStyleData(
                            icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white),
                          items: priorityOptions.map((item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPriority = value!;
                              tagColor = switch (_selectedPriority) {
                                'High' => Colors.red,
                                'Medium' => Colors.amber,
                                'Low' => Colors.green,
                                _ => Colors.grey,
                              };
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: tagColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Create Task button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: createItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(28, 125, 28, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    getButtonLabel(),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class AssignWidget extends StatelessWidget {
  const AssignWidget({
    super.key,
    required this.assignedUsers,
  });

  final List<String> assignedUsers;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Add Collaborators', style: TextStyle(color: Colors.grey[400])),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ...assignedUsers.map((user) {
              String initials;
              final parts = user.trim().split(RegExp(r"\s+"));
              if (parts.length >= 2) {
                initials = (parts[0].isNotEmpty ? parts[0][0] : '') + (parts[1].isNotEmpty ? parts[1][0] : '');
              } else if (user.contains('@')) {
                initials = user[0].toUpperCase();
              } else {
                initials = user.isNotEmpty ? user[0].toUpperCase() : '?';
              }

              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF2A2A2A),
                ),
                child: Center(
                  child: Text(
                    initials.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}