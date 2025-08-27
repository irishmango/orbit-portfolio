import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:orbit/src/features/tasks/domain/task.dart';

class CreateProjectTaskScreen extends StatefulWidget {
  final String projectId;

  const CreateProjectTaskScreen({super.key, required this.projectId});

  @override
  State<CreateProjectTaskScreen> createState() => _CreateProjectTaskScreenState();
}

class _CreateProjectTaskScreenState extends State<CreateProjectTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  int descriptionLength = 0;
  final List<String> assignedUsers = [''];
  Color tagColor = Colors.red;
  String _selectedPriority = 'High';
  final List<String> priorityOptions = ['High', 'Medium', 'Low'];

  Future<void> createTask() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final taskRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(widget.projectId)
          .collection('projectTasks')
          .doc();

      final task = Task(
        id: taskRef.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: TaskPriority.values.byName(_selectedPriority.toLowerCase()),
        isDone: false,
        projectId: widget.projectId,
      );

      await taskRef.set({
        'id': taskRef.id,
        ...task.toMap(),
      });

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
    } catch (e) {
      debugPrint('Error creating task: $e');
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
        title: const Text("Create Project Task", style: TextStyle(fontSize: 34),),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
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
                    hintText: 'Title',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

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

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: createTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(28, 125, 28, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Task',
                    style: TextStyle(color: Colors.white, fontSize: 16),
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