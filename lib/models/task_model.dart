import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String id;
  String title;
  String description;
  DateTime? startDate;
  DateTime? endDate;
  bool isDone;
  String priority; // low, medium, high
  String category; // egitim, is_, kisisel, spor, saglik, diger
  DateTime createdAt;
  String userId;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.startDate,
    this.endDate,
    this.isDone = false,
    this.priority = 'medium',
    this.category = 'kisisel',
    required this.createdAt,
    required this.userId,
  });

  // Firestore'dan gelen veriyi TaskModel'e çevir
  factory TaskModel.fromFirestore(DocumentSnapshot doc, String userId) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      isDone: data['isDone'] ?? false,
      priority: data['priority'] ?? 'medium',
      category: data['category'] ?? 'kisisel',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: userId,
    );
  }

  // Map'ten TaskModel oluştur (Hive için)
  factory TaskModel.fromMap(Map<dynamic, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'])
          : null,
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
      isDone: map['isDone'] ?? false,
      priority: map['priority'] ?? 'medium',
      category: map['category'] ?? 'kisisel',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      userId: map['userId'] ?? '',
    );
  }

  // TaskModel'i Map'e çevir (Hive için)
  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'isDone': isDone,
      'priority': priority,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'userId': userId,
    };
  }

  // TaskModel'i Map'e çevir (Firestore için)
  Map<String, dynamic> toFirestoreMap() {
    return {
      'title': title,
      'description': description,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isDone': isDone,
      'priority': priority,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Kopyalama metodu
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isDone,
    String? priority,
    String? category,
    DateTime? createdAt,
    String? userId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isDone: isDone ?? this.isDone,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
