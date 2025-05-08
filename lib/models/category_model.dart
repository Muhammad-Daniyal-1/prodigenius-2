import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String title;
  final String description;
  final String userId;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.title,
    required this.description,
    required this.userId,
    required this.createdAt,
  });

  // Convert model to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create model from Firestore document
  factory CategoryModel.fromMap(Map<String, dynamic> map, String documentId) {
    return CategoryModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // Create a copy of the model with updated fields
  CategoryModel copyWith({
    String? id,
    String? title,
    String? description,
    String? userId,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
