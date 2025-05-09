import 'package:flutter/material.dart';
import '../models/task_model.dart';
import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final Map<String, Timer> _deadlineTimers = {};
  final List<TaskModel> _activeTasks = [];
  bool _isInitialized = false;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  void initialize(GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey) {
    _scaffoldMessengerKey = scaffoldMessengerKey;
    _isInitialized = true;
    debugPrint('Simple notification service initialized');
  }

  // Request notification permissions
  Future<void> requestPermissions() async {
    // For in-app notifications using SnackBar, we don't need special permissions
    // But we should log this for debugging
    debugPrint('Requesting notification permissions');
  }

  // Schedule a notification for a task deadline
  Future<void> scheduleTaskDeadlineNotification(TaskModel task) async {
    if (!_isInitialized || _scaffoldMessengerKey == null) {
      debugPrint('Notification service not initialized');
      return;
    }

    // Calculate time before deadline to show notification
    final now = DateTime.now();
    final deadline = task.dueDate;
    
    // Don't schedule notifications for past deadlines
    if (deadline.isBefore(now)) {
      debugPrint('Task deadline is in the past, not scheduling notification: ${task.title}');
      return;
    }

    // Remove any existing instance of this task
    _activeTasks.removeWhere((t) => t.id == task.id);
    
    // Add task to active tasks list
    _activeTasks.add(task);
    
    // Schedule deadline checks
    _scheduleDeadlineCheck(task, const Duration(days: 1));
    _scheduleDeadlineCheck(task, const Duration(hours: 3));
    _scheduleDeadlineCheck(task, const Duration(hours: 1));

    // Show an immediate notification if the task is due soon (within 3 hours)
    final timeLeft = deadline.difference(now);
    if (timeLeft.inHours <= 3) {
      // Show a notification right away
      _showDeadlineNotification(task, Duration(minutes: timeLeft.inMinutes));
    }

    debugPrint('Scheduled deadline checks for task: ${task.title}, due on ${task.dueDate}');
  }

  // Helper method to schedule a deadline check
  void _scheduleDeadlineCheck(TaskModel task, Duration timeBeforeDeadline) {
    final deadline = task.dueDate;
    final notificationTime = deadline.subtract(timeBeforeDeadline);
    
    // Don't schedule if notification time is in the past
    if (notificationTime.isBefore(DateTime.now())) {
      return;
    }

    // Calculate delay until notification time
    final delay = notificationTime.difference(DateTime.now());
    
    // Create a unique timer ID
    final String timerId = '${task.id}_${timeBeforeDeadline.inMinutes}';
    
    // Cancel existing timer if any
    if (_deadlineTimers.containsKey(timerId)) {
      _deadlineTimers[timerId]?.cancel();
    }
    
    // Schedule a timer
    _deadlineTimers[timerId] = Timer(delay, () {
      _showDeadlineNotification(task, timeBeforeDeadline);
    });
    
    debugPrint('Scheduled deadline check for ${timeBeforeDeadline.inHours} hours before deadline for task: ${task.title}');
  }
  
  // Show an in-app notification for a task deadline
  void _showDeadlineNotification(TaskModel task, Duration timeBeforeDeadline) {
    if (_scaffoldMessengerKey?.currentState == null) {
      debugPrint('ScaffoldMessengerState not available');
      return;
    }
    
    String notificationMessage;
    if (timeBeforeDeadline.inDays >= 1) {
      notificationMessage = 'Due tomorrow! Task: ${task.title}';
    } else if (timeBeforeDeadline.inHours >= 3) {
      notificationMessage = 'Due in 3 hours! Task: ${task.title}';
    } else if (timeBeforeDeadline.inHours >= 1) {
      notificationMessage = 'Due in 1 hour! Task: ${task.title}';
    } else {
      notificationMessage = 'Due in ${timeBeforeDeadline.inMinutes} minutes! Task: ${task.title}';
    }
    
    // Show a snackbar
    try {
      _scaffoldMessengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.alarm, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notificationMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Navigate to task details
              debugPrint('Notification tapped for task: ${task.title}');
            },
          ),
        ),
      );
      debugPrint('Showed deadline notification for task: ${task.title}');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Cancel all notifications for a specific task
  Future<void> cancelTaskNotifications(TaskModel task) async {
    // Cancel timers for this task
    final taskTimerIds = _deadlineTimers.keys.where((id) => id.startsWith('${task.id}_'));
    for (final timerId in taskTimerIds) {
      _deadlineTimers[timerId]?.cancel();
      _deadlineTimers.remove(timerId);
    }
    
    // Remove task from active tasks
    _activeTasks.removeWhere((t) => t.id == task.id);
    
    debugPrint('Cancelled all deadline checks for task: ${task.title}');
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    // Cancel all timers
    for (final timer in _deadlineTimers.values) {
      timer.cancel();
    }
    _deadlineTimers.clear();
    _activeTasks.clear();
    
    debugPrint('Cancelled all deadline checks');
  }
  
  // Start a background task to check for upcoming deadlines
  void startDeadlineChecker() {
    // Check every minute for upcoming deadlines
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkUpcomingDeadlines();
    });
    
    debugPrint('Started deadline checker');
  }
  
  // Check for upcoming deadlines
  void _checkUpcomingDeadlines() {
    final now = DateTime.now();
    debugPrint('Checking upcoming deadlines. Active tasks: ${_activeTasks.length}');
    
    for (final task in _activeTasks) {
      final deadline = task.dueDate;
      final timeLeft = deadline.difference(now);
      
      debugPrint('Task: ${task.title}, Due: ${task.dueDate}, Time left: ${timeLeft.inMinutes} minutes');
      
      // If deadline is within the next hour and we haven't shown a notification yet
      if (timeLeft.inHours <= 1 && timeLeft.inMinutes > 0) {
        debugPrint('Showing notification for task: ${task.title} due in ${timeLeft.inMinutes} minutes');
        _showDeadlineNotification(task, Duration(minutes: timeLeft.inMinutes));
      }
    }
  }
}
