import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_calendar_service.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';

class CalendarSyncScreen extends StatefulWidget {
  static const String routeName = '/calendar_sync';

  const CalendarSyncScreen({super.key});

  @override
  State<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends State<CalendarSyncScreen> {
  final GoogleCalendarService _googleCalendarService = GoogleCalendarService();
  final FirestoreService _firestoreService = FirestoreService();
  
  bool _isLoading = false;
  List<TaskModel> _tasks = [];
  List<calendar.Event> _calendarEvents = [];
  List<TaskModel> _selectedTasks = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Check if Google Calendar is connected
      final isConnected = await _googleCalendarService.isCalendarConnected();
      if (!isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please connect to Google Calendar first'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }
      
      // Load tasks
      final userId = await _getUserId();
      if (userId != null) {
        _tasks = await _firestoreService.getTasksByUser(userId);
      }
      
      // Load calendar events
      _calendarEvents = await _googleCalendarService.getCalendarEvents();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<String?> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('userId');
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return null;
    }
  }
  
  void _toggleTaskSelection(TaskModel task) {
    setState(() {
      if (_selectedTasks.contains(task)) {
        _selectedTasks.remove(task);
      } else {
        _selectedTasks.add(task);
      }
    });
  }
  
  Future<void> _syncSelectedTasks() async {
    if (_selectedTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one task to sync'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    int successCount = 0;
    int failCount = 0;
    
    for (final task in _selectedTasks) {
      try {
        final success = await _googleCalendarService.addTaskToCalendar(task);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
        debugPrint('Error syncing task: $e');
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedTasks.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synced $successCount tasks successfully${failCount > 0 ? ', $failCount failed' : ''}'),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
      
      // Reload calendar events after sync
      _loadCalendarEvents();
    }
  }
  
  Future<void> _loadCalendarEvents() async {
    try {
      final events = await _googleCalendarService.getCalendarEvents();
      if (mounted) {
        setState(() {
          _calendarEvents = events;
        });
      }
    } catch (e) {
      debugPrint('Error loading calendar events: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar Sync'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedTasks.isNotEmpty)
            TextButton.icon(
              onPressed: _syncSelectedTasks,
              icon: const Icon(Icons.sync, color: Colors.white),
              label: Text(
                'Sync (${_selectedTasks.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Tasks'),
                      Tab(text: 'Calendar Events'),
                    ],
                    labelColor: Colors.deepPurple,
                    indicatorColor: Colors.deepPurple,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tasks Tab
                        _buildTasksTab(),
                        
                        // Calendar Events Tab
                        _buildCalendarEventsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildTasksTab() {
    if (_tasks.isEmpty) {
      return const Center(
        child: Text('No tasks found'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final isSelected = _selectedTasks.contains(task);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
                ? const BorderSide(color: Colors.deepPurple, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => _toggleTaskSelection(task),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleTaskSelection(task),
                    activeColor: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.status,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(task.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCalendarEventsTab() {
    if (_calendarEvents.isEmpty) {
      return const Center(
        child: Text('No calendar events found'),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _calendarEvents.length,
      itemBuilder: (context, index) {
        final event = _calendarEvents[index];
        final startDate = event.start?.dateTime ?? DateTime.now();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, color: Colors.deepPurple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.summary ?? 'Untitled Event',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${startDate.day}/${startDate.month}/${startDate.year} at ${startDate.hour}:${startDate.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    event.description!,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'To Do':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
