// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Öncelik seviyeleri
enum Priority { low, medium, high }

// Kategori türleri
enum Category { egitim, is_, kisisel, spor, saglik, diger }

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Öncelik ve kategori ile görev ekleme
  Future<void> addTaskWithDates(
    String userId,
    String title,
    String description,
    DateTime startDate,
    DateTime endDate, {
    Priority priority = Priority.medium,
    Category category = Category.kisisel,
  }) {
    return _db.collection('users').doc(userId).collection('tasks').add({
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isDone': false,
      'priority': priority.name, // low, medium, high
      'category': category.name, // egitim, is_, kisisel, spor
      'createdAt': Timestamp.now(),
    });
  }

  // Görevleri getiren stream
  Stream<QuerySnapshot> getTasksStream(String userId) {
    // Her kullanıcının sadece kendi görevlerini görmesini sağlıyoruz
    return _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Yeni görev ekleme
  Future<void> addTask(
    String userId,
    String title,
    String description,
    DateTime dueDate,
  ) {
    return _db.collection('users').doc(userId).collection('tasks').add({
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'isDone': false,
      'createdAt': Timestamp.now(),
    });
  }

  // Görevi tamamlama/tamamlanmadı olarak işaretleme
  Future<void> toggleTaskStatus(String userId, String taskId, bool isDone) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .update({'isDone': isDone});
  }

  // Görevi silme
  Future<void> deleteTask(String userId, String taskId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // Görevi güncelleme
  Future<void> updateTask(
    String userId,
    String taskId, {
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    Priority? priority,
    Category? category,
  }) {
    Map<String, dynamic> updateData = {};

    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (startDate != null) {
      updateData['startDate'] = Timestamp.fromDate(startDate);
    }
    if (endDate != null) updateData['endDate'] = Timestamp.fromDate(endDate);
    if (priority != null) updateData['priority'] = priority.name;
    if (category != null) updateData['category'] = category.name;

    return _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .doc(taskId)
        .update(updateData);
  }
}
