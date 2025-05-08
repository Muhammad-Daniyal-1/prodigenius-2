import 'package:flutter/material.dart';
import '../models/task_model.dart';

/// Widget for displaying individual task cards
class TaskCard extends StatelessWidget {
  final String title;
  final String date;
  final String description;
  final String? category;
  final TaskPriority? priority;
  final bool completed;
  final bool? prioritizedByAI;
  // final List<Color> teamAvatars;

  const TaskCard({
    super.key,
    required this.title,
    required this.date,
    required this.description,
    this.category,
    this.priority,
    this.completed = false,
    this.prioritizedByAI,
    // required this.teamAvatars,
  });

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.lowest:
        return Colors.grey;
      case TaskPriority.low:
        return Colors.blue;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.deepOrange;
      case TaskPriority.highest:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration:
                        completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (completed) const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (category != null && category!.isNotEmpty) ...[  
                const SizedBox(width: 8),
                const Icon(Icons.category, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  category!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description.isNotEmpty ? description : 'No description provided',
            style: TextStyle(
              color: description.isNotEmpty ? Colors.black54 : Colors.grey,
              fontSize: 14,
              fontStyle: description.isNotEmpty ? FontStyle.normal : FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (category == null || category!.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'No category assigned',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!completed && priority != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priority!).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getPriorityColor(priority!)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag,
                        color: _getPriorityColor(priority!),
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        priority!.name,
                        style: TextStyle(
                          color: _getPriorityColor(priority!),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              if (prioritizedByAI != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: prioritizedByAI! ? Colors.purple.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: prioritizedByAI! ? Colors.purple : Colors.blue,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        prioritizedByAI! ? Icons.auto_awesome : Icons.person,
                        color: prioritizedByAI! ? Colors.purple : Colors.blue,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        prioritizedByAI! ? 'AI' : 'User',
                        style: TextStyle(
                          color: prioritizedByAI! ? Colors.purple : Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
