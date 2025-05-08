import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../models/task_model.dart';
import 'notification_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Collections
  final String _categoriesCollection = 'categories';
  final String _tasksCollection = 'tasks';

  // Category methods
  Future<void> addCategory(CategoryModel category) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_categoriesCollection)
          .add(category.toMap());

      // Update the category with the generated ID
      await docRef.update({'id': docRef.id});
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CategoryModel>> getCategoriesByUser(String userId) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection(_categoriesCollection)
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map(
            (doc) => CategoryModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _firestore
          .collection(_categoriesCollection)
          .doc(category.id)
          .update(category.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      // Delete the category
      await _firestore
          .collection(_categoriesCollection)
          .doc(categoryId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Task methods
  Future<void> addTask(TaskModel task) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_tasksCollection)
          .add(task.toMap());

      // Update the task with the generated ID
      await docRef.update({'id': docRef.id});
      
      // Create a new task model with the generated ID
      final updatedTask = TaskModel(
        id: docRef.id,
        userId: task.userId,
        title: task.title,
        description: task.description,
        categoryId: task.categoryId,
        dueDate: task.dueDate,
        priority: task.priority,
        status: task.status,
        createdAt: task.createdAt,
        complexity: task.complexity,
        prototizeByAI: task.prototizeByAI,
      );
      
      // Schedule deadline notifications
      await _notificationService.scheduleTaskDeadlineNotification(updatedTask);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TaskModel>> getTasksByUser(
    String userId, {
    String? categoryId,
    String? status,
  }) async {
    try {
      Query query = _firestore
          .collection(_tasksCollection)
          .where('userId', isEqualTo: userId);

      // Filter by category if provided
      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      // Filter by status if provided
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      QuerySnapshot querySnapshot =
          await query.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs
          .map(
            (doc) =>
                TaskModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _firestore
          .collection(_tasksCollection)
          .doc(task.id)
          .update(task.toMap());
      
      // Cancel existing notifications and schedule new ones
      await _notificationService.cancelTaskNotifications(task);
      await _notificationService.scheduleTaskDeadlineNotification(task);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTaskByCondition(
    String taskId,
    Map<String, dynamic> data,
    condition,
  ) async {
    try {
      await _firestore.collection(_tasksCollection).doc(taskId).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      // Get the task before deleting to cancel notifications
      final docSnapshot = await _firestore.collection(_tasksCollection).doc(taskId).get();
      if (docSnapshot.exists) {
        final task = TaskModel.fromMap(docSnapshot.data() as Map<String, dynamic>, taskId);
        await _notificationService.cancelTaskNotifications(task);
      }
      
      await _firestore.collection(_tasksCollection).doc(taskId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Method to update task status
  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await _firestore.collection(_tasksCollection).doc(taskId).update({
        'status': status,
      });
      
      // If task is completed, cancel the notifications
      if (status == 'Completed') {
        final docSnapshot = await _firestore.collection(_tasksCollection).doc(taskId).get();
        if (docSnapshot.exists) {
          final task = TaskModel.fromMap(docSnapshot.data() as Map<String, dynamic>, taskId);
          await _notificationService.cancelTaskNotifications(task);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<TaskModel>> listenToUserTasks(String userId) {
    return _firestore
        .collection(_tasksCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => TaskModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();
        });
  }
}
