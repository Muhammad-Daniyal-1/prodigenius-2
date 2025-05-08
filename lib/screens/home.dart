import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:prodigenius/models/task_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../components/task_card.dart';
import '../components/bottom_sheets/add_task_sheet.dart';
import '../components/bottom_sheets/add_category_sheet.dart';
import '../ml/ml_service.dart';
import '../ml/preprocessing.dart';
import 'package:logger/logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String _userName = 'User';
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('email') ?? 'User';
    });
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                _buildOptionItem(
                  title: 'Add Task',
                  icon: Icons.task,
                  onTap: () {
                    Navigator.pop(context);
                    _showAddTaskSheet();
                  },
                ),
                const Divider(height: 0),
                _buildOptionItem(
                  title: 'Add Category',
                  icon: Icons.category,
                  onTap: () {
                    Navigator.pop(context);
                    _showAddCategorySheet();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildOptionItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

  void _showAddTaskSheet() async {
    // setState(() {
    //   _isLoading = true; // Add this variable to your parent class
    // });

    try {
      // Get userId first if needed
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        // Fetch categories
        final categories = await _firestoreService.getCategoriesByUser(userId);

        if (mounted) {
          // setState(() {
          //   _isLoading = false;
          // });

          // Show bottom sheet with categories
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder:
                (context) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: AddTaskBottomSheet(
                    firestoreService: _firestoreService,
                    categories: categories,
                  ),
                ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: ${e.toString()}')),
        );
      }
    }
  }

  void _showAddCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AddCategoryBottomSheet(firestoreService: _firestoreService),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.amber,
              child: Icon(Icons.person, color: Colors.white),
            ),
            SizedBox(width: screenWidth * 0.03),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hello,",
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: const HomeScreenBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showOptionsMenu,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Body component to keep the main class cleaner
class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({super.key});

  @override
  State<HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  final FirestoreService _firestoreService = FirestoreService();
  List<TaskModel> _tasks = [];
  String? _userId;
  StreamSubscription? _tasksSubscription;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      setState(() {
        _userId = userId;
      });
      _setupTasksListener();
    }
  }

  void _setupTasksListener() {
    if (_userId == null) return;

    try {
      // Cancel existing subscription if any
      _tasksSubscription?.cancel();

      // Set up real-time listener
      _tasksSubscription = _firestoreService
          .listenToUserTasks(_userId!)
          .listen(
            (tasks) {
              if (kDebugMode) {
                print("Stream update received with ${tasks.length} tasks");
              }
              if (tasks.isNotEmpty) {
                if (kDebugMode) {
                  print("First task: ${tasks[0].title}, ID: ${tasks[0].id}");
                }
              }

              if (mounted) {
                setState(() {
                  _tasks = tasks;
                });
              }
            },
            onError: (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading tasks: ${e.toString()}'),
                  ),
                );
              }
            },
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up tasks listener: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _loadTasks() async {
    if (_userId == null) return;

    try {
      final tasks = await _firestoreService.getTasksByUser(_userId!);

      if (mounted) {
        setState(() {
          _tasks = tasks;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading tasks: ${e.toString()}')),
        );
      }
    }
  }

  Future<List<TaskModel>> _getTasksByStatus(String status) async {
    List<TaskModel> tasks =
        _tasks.where((task) => task.status == status).toList();

    if (status == "In Progress" &&
        tasks.any((task) => task.prototizeByAI == true)) {
      // Prepare inputs for ML model
      List<String> dates =
          tasks
              .map((task) => task.dueDate.toIso8601String().split('T')[0])
              .toList();
      List<String> times =
          tasks
              .map(
                (task) => task.dueDate
                    .toIso8601String()
                    .split('T')[1]
                    .substring(0, 5),
              )
              .toList();

      // // Convert priorities to integer values
      List<int> priorities =
          tasks.map((task) {
            // Convert TaskPriority enum to integer (1-5)
            return switch (task.priority) {
              TaskPriority.lowest => 1,
              TaskPriority.low => 2,
              TaskPriority.medium => 3,
              TaskPriority.high => 4,
              TaskPriority.highest => 5,
            };
          }).toList();

      // // Convert data to normalized input
      List<double> input = preprocessData(dates, times, priorities);

      // // Run predictions
      List<double> predictions = [];
      for (int i = 0; i < tasks.length; i++) {
        double score = await MLService.runInference([
          input[i * 2],
          input[i * 2 + 1],
        ]);
        predictions.add(score);
      }

      for (int i = 0; i < tasks.length; i++) {
        // round the prediction to the nearest big integer
        int priority = predictions[i].round();

        // create updated task with new priority

        // only update if the prioritizeByAI is true
        if (tasks[i].prototizeByAI == true) {
          // update the task in firebase
          TaskModel updatedTask = tasks[i].copyWith(
            priority: TaskPriority.values[priority],
          );

          // update the task in firebase
          await _firestoreService.updateTask(updatedTask);
        }
      }

      // // Sort tasks based on predicted priority scores (higher score = higher priority)
      List<TaskModel> sortedTasks = List.from(tasks);
      sortedTasks.sort((a, b) {
        int indexA = tasks.indexOf(a);
        int indexB = tasks.indexOf(b);
        return predictions[indexB].compareTo(
          predictions[indexA],
        ); // Sort in descending order
      });

      return sortedTasks;
    }

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<TaskModel>>>(
      future: Future.wait([
        _getTasksByStatus('In Progress'),
        _getTasksByStatus('To Do'),
        _getTasksByStatus('Completed'),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final inProgressTasks = snapshot.data![0];
        final todoTasks = snapshot.data![1];
        final completedTasks = snapshot.data![2];

        return RefreshIndicator(
          onRefresh: _loadTasks,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // In Progress Section
                Text(
                  "In Progress (${inProgressTasks.length})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTaskList(inProgressTasks, true),
                const SizedBox(height: 20),

                // To Do Section
                Text(
                  "To Do (${todoTasks.length})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTaskList(todoTasks, true),
                const SizedBox(height: 20),

                // Completed Section
                Text(
                  "Completed (${completedTasks.length})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTaskList(completedTasks, false),
                const SizedBox(height: 80), // Prevent bottom overflow
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskList(List<TaskModel> tasks, bool isScrollable) {
    if (tasks.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          "No tasks found",
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    if (isScrollable) {
      return SizedBox(
        height: 200,
        child: PageView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskCard(task);
          },
        ),
      );
    } else {
      return Column(
        children: tasks.map((task) => _buildTaskCard(task)).toList(),
      );
    }
  }

  Widget _buildTaskCard(TaskModel task) {
    // Calculate progress percentage based on status
    int progress = 0;
    if (task.status == 'In Progress') {
      progress = 50;
    } else if (task.status == 'Completed') {
      progress = 100;
    }

    // Format date
    final dueDate = task.dueDate;
    final formattedDate = "${dueDate.day}/${dueDate.month}/${dueDate.year}";

    return TaskCard(
      title: task.title,
      date: formattedDate,
      description: task.description,
      progress: progress,
      completed: task.status == 'Completed',
      teamAvatars: const [Colors.blue, Colors.green], // Default avatars
    );
  }
}
