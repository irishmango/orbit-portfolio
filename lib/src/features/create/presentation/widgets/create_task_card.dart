import 'package:flutter/material.dart';
import 'package:orbit/src/features/create/presentation/widgets/priority_icon.dart';

class CreateTaskCard extends StatelessWidget {
  const CreateTaskCard({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.selectedPriority,
    required this.onPrioritySelected,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String selectedPriority;
  final Function(String) onPrioritySelected;

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
                  controller: titleController,
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
                  controller: descriptionController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Description',
                    hintStyle: TextStyle(color: Colors.white),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            
            children: [
              PriorityIcon(
                label: "Low",
                color: Colors.green,
                isSelected: selectedPriority == 'Low',
                onTap: () => onPrioritySelected('Low'),
              ),
              const SizedBox(height: 10),
              PriorityIcon(
                label: "Medium",
                color: Colors.orange,
                isSelected: selectedPriority == 'Medium',
                onTap: () => onPrioritySelected('Medium'),
              ),
              const SizedBox(height: 10),
              PriorityIcon(
                label: "High",
                color: Colors.red,
                isSelected: selectedPriority == 'High',
                onTap: () => onPrioritySelected('High'),
              ),
            ],
          )
        ],
      ),
    );
  }
}
