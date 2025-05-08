import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/bottom_sheet_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/category_model.dart';
import '../../models/task_model.dart';

class AddTaskBottomSheet extends StatefulWidget {
  final FirestoreService firestoreService;
  final List<CategoryModel> categories;

  const AddTaskBottomSheet({
    super.key,
    required this.firestoreService,
    required this.categories,
  });

  @override
  State<AddTaskBottomSheet> createState() => _AddTaskBottomSheetState();
}

class _AddTaskBottomSheetState extends State<AddTaskBottomSheet> {
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
  bool _prototizeByAI = true;

  // Define statuses
  final List<String> _statuses = ['To Do', 'In Progress', 'Completed'];

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Initialize date and time controllers
    final now = DateTime.now();
    _dateController.text = '${now.day}/${now.month}/${now.year}';
    _timeController.text =
        '${_dueTime.hour}:${_dueTime.minute.toString().padLeft(2, '0')}';
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
          if (_categories.isNotEmpty) {
            _selectedCategoryId = _categories.first.id;
          }
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
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    if (_categories.isEmpty) {
      return _buildStyledDropdown(
        label: 'Category',
        child: const SizedBox(
          height: 48,
          child: Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return _buildStyledDropdown(
      label: 'Category',
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedCategoryId,
            hint: const Text('Select Category'),
            icon: const Icon(Icons.arrow_drop_down),
            borderRadius: BorderRadius.circular(8),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No Category'),
              ),
              ..._categories.map(
                (category) => DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.title),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategoryId = value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    return _buildStyledDropdown(
      label: 'Priority',
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<TaskPriority>(
            isExpanded: true,
            value: _selectedPriority,
            icon: const Icon(Icons.arrow_drop_down),
            borderRadius: BorderRadius.circular(8),
            items:
                TaskPriority.values.map((priority) {
                  return DropdownMenuItem<TaskPriority>(
                    value: priority,
                    child: Row(
                      children: [
                        _getPriorityIcon(priority),
                        const SizedBox(width: 8),
                        Text(priority.name),
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
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return _buildStyledDropdown(
      label: 'Status',
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            isExpanded: true,
            value: _selectedStatus,
            icon: const Icon(Icons.arrow_drop_down),
            borderRadius: BorderRadius.circular(8),
            items:
                _statuses.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Row(
                      children: [
                        _getStatusIcon(status),
                        const SizedBox(width: 8),
                        Text(status),
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
      ),
    );
  }

  Widget _getPriorityIcon(TaskPriority priority) {
    Color color;
    IconData icon = Icons.flag;

    switch (priority) {
      case TaskPriority.lowest:
        color = Colors.grey;
        break;
      case TaskPriority.low:
        color = Colors.blue;
        break;
      case TaskPriority.medium:
        color = Colors.green;
        break;
      case TaskPriority.high:
        color = Colors.orange;
        break;
      case TaskPriority.highest:
        color = Colors.red;
        break;
    }

    return Icon(icon, color: color, size: 18);
  }

  Widget _getStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status) {
      case 'To Do':
        icon = Icons.circle_outlined;
        color = Colors.grey;
        break;
      case 'In Progress':
        icon = Icons.sync;
        color = Colors.blue;
        break;
      case 'Completed':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icon = Icons.circle_outlined;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 18);
  }

  Widget _buildDateAndTimeSection() {
    return Row(
      children: [
        Expanded(
          child: BottomSheetWidgets.buildDateTimeField(
            context,
            controller: _dateController,
            label: "Due Date",
            hint: "dd/mm/yy",
            icon: Icons.calendar_today,
            onTap: _selectDate,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: BottomSheetWidgets.buildDateTimeField(
            context,
            controller: _timeController,
            label: "Due Time",
            hint: "hh : mm",
            icon: Icons.access_time,
            onTap: _selectTime,
          ),
        ),
      ],
    );
  }

  Future<void> _saveTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
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
      final task = TaskModel(
        id: '', // Firestore will generate this
        userId: _userId!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        dueDate: _dueDate,
        priority: _selectedPriority,
        status: _selectedStatus,
        createdAt: DateTime.now(),
        prototizeByAI: _prototizeByAI,
      );

      await widget.firestoreService.addTask(task);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating task: ${e.toString()}')),
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
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BottomSheetWidgets.buildSheetHandle(),
                BottomSheetWidgets.buildSheetTitle('New Task'),
                const SizedBox(height: 10),
                Divider(color: Colors.grey[300]),
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
                      onSubmit: _saveTask,
                      submitText: 'Create Task',
                    ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
