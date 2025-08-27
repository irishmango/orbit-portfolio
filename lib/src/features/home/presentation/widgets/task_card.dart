import 'package:flutter/material.dart';
import 'package:orbit/src/features/tasks/domain/task.dart';
import 'package:orbit/theme.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final Color? borderColor;

  const TaskCard({
    super.key,
    required this.task,
    this.borderColor,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.card.copyWith(
        border: widget.borderColor != null
            ? Border.all(color: widget.borderColor!, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.task.title,
            style: AppTextStyles.body.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Text(widget.task.description, style: TextStyle(color: Colors.grey[300]))
              ]
            ),
          )
        ],
      ),
    );
  }
}