import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';

class CacheService {
  static const String _tasksBoxName = 'tasks_cache';
  static const String _lastSyncKey = 'last_sync_time';

  Box<Map>? _tasksBox;

  // Singleton pattern
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Hive'ı başlat
  Future<void> init() async {
    await Hive.initFlutter();
    _tasksBox = await Hive.openBox<Map>(_tasksBoxName);
  }

  // Box'ın açık olduğundan emin ol
  Future<Box<Map>> get _box async {
    if (_tasksBox == null || !_tasksBox!.isOpen) {
      _tasksBox = await Hive.openBox<Map>(_tasksBoxName);
    }
    return _tasksBox!;
  }

  // Tüm görevleri cache'e kaydet
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    final box = await _box;
    await box.clear(); // Önce temizle

    for (final task in tasks) {
      await box.put(task.id, task.toHiveMap());
    }

    // Son senkronizasyon zamanını kaydet
    await box.put(_lastSyncKey, {'time': DateTime.now().toIso8601String()});
  }

  // Tek bir görevi cache'e ekle
  Future<void> cacheTask(TaskModel task) async {
    final box = await _box;
    await box.put(task.id, task.toHiveMap());
  }

  // Cache'den tüm görevleri al
  Future<List<TaskModel>> getCachedTasks() async {
    final box = await _box;
    final List<TaskModel> tasks = [];

    for (final key in box.keys) {
      if (key == _lastSyncKey) continue;

      final data = box.get(key);
      if (data != null) {
        try {
          tasks.add(TaskModel.fromMap(Map<String, dynamic>.from(data)));
        } catch (_) {}
      }
    }

    // Oluşturulma tarihine göre sırala (en yeni en üstte)
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return tasks;
  }

  // Tek bir görevi güncelle
  Future<void> updateCachedTask(TaskModel task) async {
    final box = await _box;
    await box.put(task.id, task.toHiveMap());
  }

  // Tek bir görevi sil
  Future<void> deleteCachedTask(String taskId) async {
    final box = await _box;
    await box.delete(taskId);
  }

  // Görev durumunu toggle et
  Future<void> toggleCachedTaskStatus(String taskId) async {
    final box = await _box;
    final data = box.get(taskId);

    if (data != null) {
      final task = TaskModel.fromMap(Map<String, dynamic>.from(data));
      final updatedTask = TaskModel(
        id: task.id,
        title: task.title,
        description: task.description,
        startDate: task.startDate,
        endDate: task.endDate,
        isDone: !task.isDone,
        priority: task.priority,
        category: task.category,
        createdAt: task.createdAt,
        userId: task.userId,
      );
      await box.put(taskId, updatedTask.toHiveMap());
    }
  }

  // Cache'i tamamen temizle
  Future<void> clearCache() async {
    final box = await _box;
    await box.clear();
  }

  // Son senkronizasyon zamanını al
  Future<DateTime?> getLastSyncTime() async {
    final box = await _box;
    final data = box.get(_lastSyncKey);

    if (data != null && data['time'] != null) {
      return DateTime.tryParse(data['time']);
    }
    return null;
  }

  // Cache'de veri var mı?
  Future<bool> hasCachedData() async {
    final box = await _box;
    return box.keys.where((key) => key != _lastSyncKey).isNotEmpty;
  }

  // Görev sayısını al
  Future<int> getCachedTaskCount() async {
    final box = await _box;
    return box.keys.where((key) => key != _lastSyncKey).length;
  }
}
