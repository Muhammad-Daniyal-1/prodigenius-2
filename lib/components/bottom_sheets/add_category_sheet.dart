import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/bottom_sheet_widgets.dart';
import '../../services/firestore_service.dart';
import '../../models/category_model.dart';

class AddCategoryBottomSheet extends StatefulWidget {
  final FirestoreService firestoreService;

  const AddCategoryBottomSheet({super.key, required this.firestoreService});

  @override
  State<AddCategoryBottomSheet> createState() => _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends State<AddCategoryBottomSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category title')),
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
      final category = CategoryModel(
        id: '', // Firestore will generate this
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        userId: _userId!,
        createdAt: DateTime.now(),
      );

      await widget.firestoreService.addCategory(category);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating category: ${e.toString()}')),
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
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.7,
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
                BottomSheetWidgets.buildSheetTitle('New Category'),
                const SizedBox(height: 10),
                Divider(color: Colors.grey[300]),
                BottomSheetWidgets.buildTextField(
                  controller: _titleController,
                  label: "Category Title",
                  hint: "Enter category name...",
                ),
                const SizedBox(height: 15),
                BottomSheetWidgets.buildTextField(
                  controller: _descriptionController,
                  label: "Description",
                  hint: "Enter category description...",
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : BottomSheetWidgets.buildActionButtons(
                      context,
                      onCancel: () => Navigator.pop(context),
                      onSubmit: _saveCategory,
                      submitText: 'Create Category',
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
