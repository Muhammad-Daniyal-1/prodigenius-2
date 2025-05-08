import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';

enum TaskPriority { lowest, low, medium, high, highest }

extension TaskPriorityExtension on TaskPriority {
  String get name {
    switch (this) {
      case TaskPriority.lowest:
        return 'Lowest';
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.highest:
        return 'Highest';
    }
  }

  static TaskPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'lowest':
        return TaskPriority.lowest;
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      case 'highest':
        return TaskPriority.highest;
      default:
        return TaskPriority.medium;
    }
  }
}

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? categoryId;
  final DateTime dueDate;
  final TaskPriority priority;
  final String status; // New, InProgress, Completed
  final DateTime createdAt;
  final double? complexity; // ML-predicted complexity rating (1-5)
  final bool? prototizeByAI;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.categoryId,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.complexity,
    this.prototizeByAI,
  });

  // Convert model to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.index,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'complexity': complexity,
      'prototizeByAI': prototizeByAI,
    };
  }

  // Create model from Firestore document
  factory TaskModel.fromMap(Map<String, dynamic> map, String id) {
    return TaskModel(
      id: id,
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      categoryId: map['categoryId'],
      dueDate: DateTime.parse(map['dueDate']),
      priority: TaskPriority.values[map['priority']],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
      complexity: map['complexity'],
      prototizeByAI: map['prototizeByAI'],
    );
  }

  // Create a copy of the model with updated fields
  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? categoryId,
    DateTime? dueDate,
    TaskPriority? priority,
    String? status,
    DateTime? createdAt,
    double? complexity,
    bool? prototizeByAI,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      complexity: complexity ?? this.complexity,
      prototizeByAI: prototizeByAI ?? this.prototizeByAI,
    );
  }
}

// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// Future<void> initializeNotifications() async {
//   const AndroidInitializationSettings initializationSettingsAndroid =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   const InitializationSettings initializationSettings = InitializationSettings(
//     android: initializationSettingsAndroid,
//   );

//   await flutterLocalNotificationsPlugin.initialize(initializationSettings);
// }

// Future<void> scheduleTaskNotification(TaskModel task) async {
//   const AndroidNotificationDetails androidPlatformChannelSpecifics =
//       AndroidNotificationDetails(
//         'task_notifications',
//         'Task Notifications',
//         importance: Importance.max,
//         priority: Priority.high,
//       );

//   const NotificationDetails platformChannelSpecifics = NotificationDetails(
//     android: androidPlatformChannelSpecifics,
//   );

//   await flutterLocalNotificationsPlugin.show(
//     task.id.hashCode,
//     'Task Reminder: ${task.title}',
//     'Due: ${task.dueDate.toString()}',
//     platformChannelSpecifics,
//   );
// }
