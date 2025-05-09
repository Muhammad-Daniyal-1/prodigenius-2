import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/bottom_sheet_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/category_model.dart';
import '../../models/task_model.dart';

class EditTaskBottomSheet extends StatefulWidget {
  final FirestoreService firestoreService;
  final List<CategoryModel> categories;
  final TaskModel task;

  const EditTaskBottomSheet({
    super.key,
    required this.firestoreService,
    required this.categories,
    required this.task,
  });

  @override
  State<EditTaskBottomSheet> createState() => _EditTaskBottomSheetState();
}

class _EditTaskBottomSheetState extends State<EditTaskBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  String? _userId;
  String? _selectedCategoryId;
  TaskPriority _selectedPriority = TaskPriority.medium;
  String _selectedStatus = 'To Do';
  DateTime _dueDate = DateTime.now();
  TimeOfDay _dueTime = TimeOfDay.now();
  bool _isLoading = false;
  List<CategoryModel> _categories = [];
  bool _prototizeByAI = false;

  // Define statuses
  final List<String> _statuses = ['To Do', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Initialize with task data
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description;
    _selectedCategoryId = widget.task.categoryId;
    _selectedPriority = widget.task.priority;
    _selectedStatus = widget.task.status;
    _dueDate = widget.task.dueDate;
    _dueTime = TimeOfDay(hour: _dueDate.hour, minute: _dueDate.minute);
    _prototizeByAI = widget.task.prototizeByAI ?? false;
    
    // Initialize date and time controllers
    _dateController.text = '${_dueDate.day}/${_dueDate.month}/${_dueDate.year}';
    _timeController.text = '${_dueTime.hour}:${_dueTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });

    // Load categories after getting userId
    if (_userId != null) {
      await _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    if (_userId == null) return;

    try {
      if (mounted) {
        setState(() {
          _categories = widget.categories;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: now,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _dueTime.hour,
          _dueTime.minute,
        );
        _dateController.text = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
    );
    if (picked != null) {
      setState(() {
        _dueTime = picked;
        _dueDate = DateTime(
          _dueDate.year,
          _dueDate.month,
          _dueDate.day,
          picked.hour,
          picked.minute,
        );
        _timeController.text =
            '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildStyledDropdown({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return _buildStyledDropdown(
      label: 'Category',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategoryId,
          hint: const Text('Select Category'),
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Row(
                children: [
                  // Category color indicator - using a default color since CategoryModel doesn't have a color property
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category.title,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategoryId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    return _buildStyledDropdown(
      label: 'Priority',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskPriority>(
          isExpanded: true,
          value: _selectedPriority,
          items: TaskPriority.values.map((priority) {
            return DropdownMenuItem<TaskPriority>(
              value: priority,
              child: Row(
                children: [
                  _getPriorityIcon(priority),
                  const SizedBox(width: 10),
                  Text(
                    priority.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedPriority = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return _buildStyledDropdown(
      label: 'Status',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedStatus,
          items: _statuses.map((status) {
            return DropdownMenuItem<String>(
              value: status,
              child: Row(
                children: [
                  _getStatusIcon(status),
                  const SizedBox(width: 10),
                  Text(
                    status,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedStatus = value;
              });
            }
          },
        ),
      ),
    );
  }

  Icon _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.lowest:
        return const Icon(Icons.flag, color: Colors.grey, size: 20);
      case TaskPriority.low:
        return const Icon(Icons.flag, color: Colors.blue, size: 20);
      case TaskPriority.medium:
        return const Icon(Icons.flag, color: Colors.orange, size: 20);
      case TaskPriority.high:
        return const Icon(Icons.flag, color: Colors.deepOrange, size: 20);
      case TaskPriority.highest:
        return const Icon(Icons.flag, color: Colors.red, size: 20);
    }
  }

  Icon _getStatusIcon(String status) {
    switch (status) {
      case 'To Do':
        return const Icon(Icons.circle_outlined, color: Colors.grey, size: 20);
      case 'In Progress':
        return const Icon(Icons.play_circle_filled,
            color: Colors.blue, size: 20);
      case 'Completed':
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      default:
        return const Icon(Icons.circle_outlined, color: Colors.grey, size: 20);
    }
  }

  Widget _buildDateAndTimeSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Due Date',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: TextField(
                  controller: _dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    suffixIcon: const Icon(Icons.calendar_today, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Due Time',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectTime,
                child: TextField(
                  controller: _timeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    suffixIcon: const Icon(Icons.access_time, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateTask() async {
    // Validate inputs
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
        ),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User ID not found. Please log in again.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedTask = widget.task.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        dueDate: _dueDate,
        priority: _selectedPriority,
        status: _selectedStatus,
        prototizeByAI: _prototizeByAI,
      );

      await widget.firestoreService.updateTask(updatedTask);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              BottomSheetWidgets.buildSheetHandle(),
              BottomSheetWidgets.buildSheetTitle('Edit Task'),
              const SizedBox(height: 10),
              Divider(color: Colors.grey[300]),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    BottomSheetWidgets.buildTextField(
                      controller: _titleController,
                      label: "Task Title",
                      hint: "Add Task Name...",
                    ),
                    const SizedBox(height: 15),
                    _buildCategoryDropdown(),
                    const SizedBox(height: 15),
                    _buildPriorityDropdown(),
                    const SizedBox(height: 15),
                    _buildStatusDropdown(),
                    const SizedBox(height: 15),
                    BottomSheetWidgets.buildTextField(
                      controller: _descriptionController,
                      label: "Description",
                      hint: "Add Descriptions...",
                      maxLines: 3,
                    ),
                    const SizedBox(height: 15),
                    _buildDateAndTimeSection(),
                    const SizedBox(height: 15),
                    CheckboxListTile(
                      value: _prototizeByAI,
                      onChanged: (value) {
                        setState(() {
                          _prototizeByAI = value ?? false;
                        });
                      },
                      title: const Text('Prototize/Manage by AI'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : BottomSheetWidgets.buildActionButtons(
                            context,
                            onCancel: () => Navigator.pop(context),
                            onSubmit: _updateTask,
                            submitText: 'Update Task',
                          ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
