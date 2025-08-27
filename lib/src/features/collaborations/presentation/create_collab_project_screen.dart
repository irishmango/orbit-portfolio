import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:orbit/src/features/projects/domain/project.dart';
import 'package:orbit/src/models/firestore_repository.dart';

class CreateCollabProjectScreen extends StatefulWidget {
  final String collaborationId;

  const CreateCollabProjectScreen({super.key, required this.collaborationId});

  @override
  State<CreateCollabProjectScreen> createState() => _CreateCollabProjectScreenState();
}

class _CreateCollabProjectScreenState extends State<CreateCollabProjectScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  int descriptionLength = 0;

  Future<void> createCollabProject() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final newProject = Project(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        tasks: [],
        ownerId: userId,
        tag: 'Collaboration',
      );

      final repo = FirestoreRepository();
      await repo.createCollaborationProject(widget.collaborationId, newProject);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collaboration project successfully created!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );

      _titleController.clear();
      _descriptionController.clear();
      Navigator.of(context).pop(newProject);
    } catch (e) {
      debugPrint('Error creating collaboration project: $e');
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
        title: const Text(
          "Create Collab Project",
          style: TextStyle(fontSize: 34),
        ),
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
                    hintText: 'Project Title',
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
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: createCollabProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(28, 125, 28, 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Project',
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