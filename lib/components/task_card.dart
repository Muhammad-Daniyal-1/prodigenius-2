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
  final String? taskId;
  final Function(String taskId, String newStatus)? onStatusUpdate;
  final Function(String taskId)? onEdit;
  final Function(String taskId)? onDelete;
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
    this.taskId,
    this.onStatusUpdate,
    this.onEdit,
    this.onDelete,
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

  // Show dialog with complete task details
  void _showTaskDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title with priority indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (priority != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 10, top: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(priority!).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getPriorityColor(priority!)),
                        ),
                        child: Text(
                          priority!.name,
                          style: TextStyle(
                            color: _getPriorityColor(priority!),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                
                // Date and category
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(
                      date,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    if (category != null && category!.isNotEmpty) ...[  
                      const SizedBox(width: 15),
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        category!,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                
                // Description header
                const Text(
                  'Description',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                // Description content
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    description.isNotEmpty ? description : 'No description provided',
                    style: TextStyle(
                      color: description.isNotEmpty ? Colors.black87 : Colors.grey,
                      fontSize: 14,
                      fontStyle: description.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Status and AI indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: completed ? Colors.green.withOpacity(0.2) : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        completed ? 'Completed' : 'In Progress',
                        style: TextStyle(
                          color: completed ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
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
                              prioritizedByAI! ? 'AI Prioritized' : 'User Prioritized',
                              style: TextStyle(
                                color: prioritizedByAI! ? Colors.purple : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                    if (!completed && taskId != null && onStatusUpdate != null)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onStatusUpdate!(taskId!, 'Completed');
                        },
                        child: const Text('Mark Complete'),
                      ),
                    if (!completed && onEdit != null && taskId != null)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onEdit!(taskId!);
                        },
                        child: const Text('Edit'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTaskDetailsDialog(context),
      child: Container(
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
              Row(
                children: [
                  if (completed) 
                    const Icon(Icons.check_circle, color: Colors.blue),
                  if (!completed && taskId != null && onStatusUpdate != null)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () {
                        if (onEdit != null && taskId != null) {
                          onEdit!(taskId!);
                        }
                      },
                    ),
                  if (taskId != null && onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () {
                        if (onDelete != null && taskId != null) {
                          onDelete!(taskId!);
                        }
                      },
                    ),
                  if (!completed && taskId != null && onStatusUpdate != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (String value) {
                        if (onStatusUpdate != null && taskId != null) {
                          onStatusUpdate!(taskId!, value);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'Completed',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Mark as Completed'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'In Progress',
                          child: Row(
                            children: [
                              Icon(Icons.play_circle_filled, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Mark as In Progress'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'To Do',
                          child: Row(
                            children: [
                              Icon(Icons.pending, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Move back to To Do'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
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
            maxLines: 1,
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
    ),
  );
  }
}
