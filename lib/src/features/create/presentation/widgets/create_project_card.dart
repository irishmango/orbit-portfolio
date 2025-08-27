import 'package:flutter/material.dart';
import 'package:orbit/src/features/create/presentation/widgets/custom_outlined_button.dart';

class CreateProjectCard extends StatelessWidget {
  const CreateProjectCard({
    super.key,
    required this.projectTitleController,
    required this.projectDescriptionController,
    required this.selectedPriority,
    required this.onPrioritySelected,
    required this.projectTasks,
    required this.onAddTaskPressed,
  });

  final TextEditingController projectTitleController;
  final TextEditingController projectDescriptionController;
  final String selectedPriority;
  final Function(String) onPrioritySelected;
  final List<String> projectTasks;
  final VoidCallback onAddTaskPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: projectTitleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Title:',
                    labelStyle: TextStyle(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: projectDescriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Description',
                    hintStyle: TextStyle(color: Colors.white),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 10),
                ...projectTasks.map((task) => Text(
                      "• $task",
                      style: const TextStyle(color: Colors.white),
                    )),
                
                const SizedBox(height: 20),
                CustomOutlinedButton(label: "Add Task", onPressed: onAddTaskPressed),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
