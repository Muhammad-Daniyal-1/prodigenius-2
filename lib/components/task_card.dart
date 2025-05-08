import 'package:flutter/material.dart';

/// Widget for displaying individual task cards
class TaskCard extends StatelessWidget {
  final String title;
  final String date;
  final String description;
  final int? progress;
  final bool completed;
  final List<Color> teamAvatars;

  const TaskCard({
    super.key,
    required this.title,
    required this.date,
    required this.description,
    this.progress,
    this.completed = false,
    required this.teamAvatars,
  });

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
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration:
                      completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                ),
              ),
              if (completed) const Icon(Icons.check_circle, color: Colors.blue),
            ],
          ),
          const SizedBox(height: 5),
          Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children:
                    teamAvatars
                        .map(
                          (color) => Padding(
                            padding: const EdgeInsets.only(right: 4.0),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: color,
                            ),
                          ),
                        )
                        .toList(),
              ),
              if (!completed && progress != null)
                Row(
                  children: [
                    Text("$progress%", style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        value: progress! / 100,
                        strokeWidth: 4,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
