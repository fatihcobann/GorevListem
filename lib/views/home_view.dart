import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kartal/kartal.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:todo_app/services/firestore_service.dart';
import 'package:todo_app/services/cache_service.dart';
import 'package:todo_app/models/task_model.dart';
import 'package:todo_app/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final CacheService _cacheService = CacheService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Offline modu
  bool _isOffline = false;
  List<TaskModel> _cachedTasks = [];

  // Filtreleme icin secili kategori (null = tumu)
  Category? _selectedCategory;

  // Sabit dark mode renkleri
  Color get backgroundColor => AppTheme.backgroundColor;
  Color get cardColor => AppTheme.cardColor;
  Color get textPrimary => AppTheme.textPrimary;
  Color get textSecondary => AppTheme.textSecondary;

  // Oncelik renkleri
  static const Color highPriorityColor = Color(0xFFE53935);
  static const Color mediumPriorityColor = Color(0xFFFDD835);
  static const Color lowPriorityColor = Color(0xFF43A047);

  // Kategori isimleri ve ikonlari
  Map<Category, Map<String, dynamic>> get categoryInfo => {
    Category.egitim: {
      'name': 'Eğitim',
      'icon': Icons.school,
      'color': Colors.blue,
    },
    Category.is_: {'name': 'İş', 'icon': Icons.work, 'color': Colors.orange},
    Category.kisisel: {
      'name': 'Kişisel',
      'icon': Icons.person,
      'color': Colors.purple,
    },
    Category.spor: {
      'name': 'Spor',
      'icon': Icons.fitness_center,
      'color': Colors.green,
    },
    Category.saglik: {
      'name': 'Sağlık',
      'icon': Icons.health_and_safety,
      'color': Colors.red,
    },
    Category.diger: {
      'name': 'Diğer',
      'icon': Icons.category,
      'color': Colors.grey,
    },
  };

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return highPriorityColor;
      case 'medium':
        return mediumPriorityColor;
      case 'low':
        return lowPriorityColor;
      default:
        return mediumPriorityColor;
    }
  }

  String _getPriorityText(String? priority) {
    switch (priority) {
      case 'high':
        return 'Yüksek';
      case 'medium':
        return 'Orta';
      case 'low':
        return 'Düşük';
      default:
        return 'Orta';
    }
  }

  bool _isExpired(DateTime? endDate) {
    if (endDate == null) return false;
    return endDate.isBefore(DateTime.now());
  }

  // Cache islemleri
  Future<void> _loadCachedTasks() async {
    final tasks = await _cacheService.getCachedTasks();
    // Sadece bu kullanicinin gorevlerini filtrele
    _cachedTasks = tasks.where((t) => t.userId == _userId).toList();
  }

  Future<void> _cacheTasks(List<QueryDocumentSnapshot> docs) async {
    final tasks = docs
        .map((doc) => TaskModel.fromFirestore(doc, _userId))
        .toList();
    await _cacheService.cacheTasks(tasks);
  }

  Widget _buildCachedTaskList() {
    var tasks = _cachedTasks;

    // Kategori filtresi uygula
    if (_selectedCategory != null) {
      tasks = tasks
          .where((task) => task.category == _selectedCategory!.name)
          .toList();
    }

    if (tasks.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            "Bu kategoride görev yok",
            style: TextStyle(color: textSecondary),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final task = tasks[index];
          final isDone = task.isDone;
          final priority = task.priority;
          final isExpired = _isExpired(task.endDate) && !isDone;

          Category? taskCategory;
          try {
            taskCategory = Category.values.firstWhere(
              (c) => c.name == task.category,
            );
          } catch (_) {}

          return Container(
            margin: context.padding.onlyBottomLow,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: context.border.normalBorderRadius,
              border: Border.all(
                color: isExpired
                    ? Colors.red.withValues(alpha: 0.5)
                    : AppTheme.borderColor,
                width: isExpired ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: context.padding.low,
              leading: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? AppTheme.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isDone
                        ? AppTheme.primaryColor
                        : _getPriorityColor(priority),
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.description.isNotEmpty)
                    Text(
                      task.description,
                      style: TextStyle(color: textSecondary, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(
                            priority,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getPriorityText(priority),
                          style: TextStyle(
                            color: _getPriorityColor(priority),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (taskCategory != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          categoryInfo[taskCategory]!['icon'] as IconData,
                          size: 14,
                          color: categoryInfo[taskCategory]!['color'] as Color,
                        ),
                      ],
                      if (task.endDate != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: isExpired ? Colors.red : textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd MMM').format(task.endDate!),
                          style: TextStyle(
                            color: isExpired ? Colors.red : textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: const Icon(
                Icons.wifi_off,
                color: Colors.orange,
                size: 16,
              ),
            ),
          );
        }, childCount: tasks.length),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.borderColor),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 8),
              Text("Çıkış Yap", style: TextStyle(color: textPrimary)),
            ],
          ),
          content: Text(
            "Hesabınızdan çıkış yapmak istediğinize emin misiniz?",
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("İptal", style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Çıkış Yap",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    Priority selectedPriority = Priority.medium;
    Category selectedCategory = Category.kisisel;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: context.border.normalBorderRadius,
                side: BorderSide(color: AppTheme.borderColor),
              ),
              title: Row(
                children: [
                  Icon(Icons.add_task, color: AppTheme.primaryColor),
                  SizedBox(width: context.sized.lowValue),
                  Text("Yeni Görev", style: TextStyle(color: textPrimary)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        labelText: "Başlık",
                        labelStyle: TextStyle(color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: context.border.lowBorderRadius,
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: context.border.lowBorderRadius,
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: context.sized.lowValue),
                    TextField(
                      controller: descriptionController,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        labelText: "Açıklama",
                        labelStyle: TextStyle(color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // Baslangic Tarihi
                    InkWell(
                      onTap: () async {
                        final DateTime now = DateTime.now();
                        final DateTime today = DateTime(
                          now.year,
                          now.month,
                          now.day,
                        );
                        final DateTime? picked = await showOmniDateTimePicker(
                          context: context,
                          initialDate: today,
                          firstDate: today,
                          lastDate: DateTime(2101),
                          is24HourMode: true,
                          isShowSeconds: false,
                          type: OmniDateTimePickerType.dateAndTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              startDate != null
                                  ? DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(startDate!)
                                  : "Başlangıç Tarihi",
                              style: TextStyle(color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bitis Tarihi
                    InkWell(
                      onTap: () async {
                        final DateTime now = DateTime.now();
                        final DateTime today = DateTime(
                          now.year,
                          now.month,
                          now.day,
                        );
                        final DateTime? picked = await showOmniDateTimePicker(
                          context: context,
                          initialDate: startDate ?? today,
                          firstDate: startDate ?? today,
                          lastDate: DateTime(2101),
                          is24HourMode: true,
                          isShowSeconds: false,
                          type: OmniDateTimePickerType.dateAndTime,
                        );
                        if (picked != null) {
                          setDialogState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Text(
                              endDate != null
                                  ? DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(endDate!)
                                  : "Bitiş Tarihi",
                              style: TextStyle(color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Oncelik Secimi
                    DropdownButtonFormField<Priority>(
                      initialValue: selectedPriority,
                      dropdownColor: cardColor,
                      decoration: InputDecoration(
                        labelText: "Öncelik",
                        labelStyle: TextStyle(color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: Priority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(
                            _getPriorityText(priority.name),
                            style: TextStyle(color: textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedPriority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Kategori Secimi
                    DropdownButtonFormField<Category>(
                      initialValue: selectedCategory,
                      dropdownColor: cardColor,
                      decoration: InputDecoration(
                        labelText: "Kategori",
                        labelStyle: TextStyle(color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: Category.values.map((category) {
                        final info = categoryInfo[category]!;
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                info['icon'] as IconData,
                                color: info['color'] as Color,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                info['name'] as String,
                                style: TextStyle(color: textPrimary),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("İptal", style: TextStyle(color: textSecondary)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isNotEmpty) {
                        await _addTask(
                          title: titleController.text,
                          description: descriptionController.text,
                          startDate: startDate,
                          endDate: endDate,
                          priority: selectedPriority,
                          category: selectedCategory,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text(
                      "Ekle",
                      style: TextStyle(color: Color(0xFF0A0E14)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addTask({
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? endDate,
    required Priority priority,
    required Category category,
  }) async {
    if (startDate != null && endDate != null) {
      await _firestoreService.addTaskWithDates(
        _userId,
        title,
        description,
        startDate,
        endDate,
        priority: priority,
        category: category,
      );
    } else {
      await _firestoreService.addTask(
        _userId,
        title,
        description,
        endDate ?? DateTime.now().add(const Duration(days: 7)),
      );
    }
  }

  Future<void> _confirmDeleteTask(String taskId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppTheme.borderColor),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text("Görev Sil", style: TextStyle(color: textPrimary)),
          ],
        ),
        content: Text(
          "Bu görevi silmek istediğinize emin misiniz?",
          style: TextStyle(color: textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("İptal", style: TextStyle(color: textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _firestoreService.deleteTask(_userId, taskId);
    }
  }

  // Görev detay dialog'u
  void _showTaskDetailDialog(Map<String, dynamic> task, String taskId) {
    final title = task['title'] ?? '';
    final description = task['description'] ?? '';
    final isDone = task['isDone'] ?? false;
    final priority = task['priority'] ?? 'medium';
    final categoryStr = task['category'];
    final startDate = task['startDate'] != null
        ? (task['startDate'] as Timestamp).toDate()
        : null;
    final endDate = task['endDate'] != null
        ? (task['endDate'] as Timestamp).toDate()
        : null;
    final createdAt = task['createdAt'] != null
        ? (task['createdAt'] as Timestamp).toDate()
        : null;

    Category? taskCategory;
    if (categoryStr != null) {
      try {
        taskCategory = Category.values.firstWhere((c) => c.name == categoryStr);
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.borderColor),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppTheme.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isDone
                      ? AppTheme.primaryColor
                      : _getPriorityColor(priority),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 20, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Açıklama
              if (description.isNotEmpty) ...[
                Text(
                  "Açıklama",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(color: textPrimary),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Kategori ve Öncelik
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Öncelik",
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(
                              priority,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getPriorityText(priority),
                            style: TextStyle(
                              color: _getPriorityColor(priority),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (taskCategory != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Kategori",
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (categoryInfo[taskCategory]!['color']
                                          as Color)
                                      .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  categoryInfo[taskCategory]!['icon']
                                      as IconData,
                                  size: 16,
                                  color:
                                      categoryInfo[taskCategory]!['color']
                                          as Color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  categoryInfo[taskCategory]!['name'] as String,
                                  style: TextStyle(
                                    color:
                                        categoryInfo[taskCategory]!['color']
                                            as Color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Tarihler
              if (startDate != null || endDate != null) ...[
                Text(
                  "Tarihler",
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      if (startDate != null)
                        Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Başlangıç: ",
                              style: TextStyle(color: textSecondary),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(startDate),
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      if (startDate != null && endDate != null)
                        const SizedBox(height: 8),
                      if (endDate != null)
                        Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 18,
                              color: _isExpired(endDate) && !isDone
                                  ? Colors.red
                                  : AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Bitiş: ",
                              style: TextStyle(color: textSecondary),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(endDate),
                              style: TextStyle(
                                color: _isExpired(endDate) && !isDone
                                    ? Colors.red
                                    : textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Oluşturulma tarihi
              if (createdAt != null)
                Text(
                  "Oluşturulma: ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}",
                  style: TextStyle(color: textSecondary, fontSize: 11),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Kapat", style: TextStyle(color: textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.buttonGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showEditTaskDialog(task, taskId);
              },
              icon: const Icon(Icons.edit, size: 18, color: Color(0xFF0A0E14)),
              label: const Text(
                "Düzenle",
                style: TextStyle(color: Color(0xFF0A0E14)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Görev düzenleme dialog'u
  void _showEditTaskDialog(Map<String, dynamic> task, String taskId) {
    final titleController = TextEditingController(text: task['title'] ?? '');
    final descriptionController = TextEditingController(
      text: task['description'] ?? '',
    );
    DateTime? startDate = task['startDate'] != null
        ? (task['startDate'] as Timestamp).toDate()
        : null;
    DateTime? endDate = task['endDate'] != null
        ? (task['endDate'] as Timestamp).toDate()
        : null;
    Priority selectedPriority = Priority.values.firstWhere(
      (p) => p.name == (task['priority'] ?? 'medium'),
      orElse: () => Priority.medium,
    );
    Category selectedCategory = Category.values.firstWhere(
      (c) => c.name == (task['category'] ?? 'diger'),
      orElse: () => Category.diger,
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppTheme.borderColor),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text("Görevi Düzenle", style: TextStyle(color: textPrimary)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        labelText: "Başlık",
                        labelStyle: TextStyle(color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      style: TextStyle(color: textPrimary),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Açıklama",
                        labelStyle: TextStyle(color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Başlangıç Tarihi
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showOmniDateTimePicker(
                          context: context,
                          initialDate: startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
                          is24HourMode: true,
                          isShowSeconds: false,
                          type: OmniDateTimePickerType.dateAndTime,
                        );
                        if (picked != null) {
                          setDialogState(() => startDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              startDate != null
                                  ? DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(startDate!)
                                  : "Başlangıç Tarihi",
                              style: TextStyle(color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Bitiş Tarihi
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showOmniDateTimePicker(
                          context: context,
                          initialDate: endDate ?? DateTime.now(),
                          firstDate: startDate ?? DateTime(2020),
                          lastDate: DateTime(2101),
                          is24HourMode: true,
                          isShowSeconds: false,
                          type: OmniDateTimePickerType.dateAndTime,
                        );
                        if (picked != null) {
                          setDialogState(() => endDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.event, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Text(
                              endDate != null
                                  ? DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(endDate!)
                                  : "Bitiş Tarihi",
                              style: TextStyle(color: textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Öncelik
                    DropdownButtonFormField<Priority>(
                      initialValue: selectedPriority,
                      dropdownColor: cardColor,
                      decoration: InputDecoration(
                        labelText: "Öncelik",
                        labelStyle: TextStyle(color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: Priority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(
                            _getPriorityText(priority.name),
                            style: TextStyle(color: textPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedPriority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    // Kategori
                    DropdownButtonFormField<Category>(
                      initialValue: selectedCategory,
                      dropdownColor: cardColor,
                      decoration: InputDecoration(
                        labelText: "Kategori",
                        labelStyle: TextStyle(color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: Category.values.map((category) {
                        final info = categoryInfo[category]!;
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                info['icon'] as IconData,
                                color: info['color'] as Color,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                info['name'] as String,
                                style: TextStyle(color: textPrimary),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedCategory = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("İptal", style: TextStyle(color: textSecondary)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.buttonGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.isNotEmpty) {
                        await _firestoreService.updateTask(
                          _userId,
                          taskId,
                          title: titleController.text,
                          description: descriptionController.text,
                          startDate: startDate,
                          endDate: endDate,
                          priority: selectedPriority,
                          category: selectedCategory,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: const Text(
                      "Kaydet",
                      style: TextStyle(color: Color(0xFF0A0E14)),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: context.padding.normal,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF0A0E14),
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.check,
                                  color: Color(0xFF0A0E14),
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Görev",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0A0E14),
                                        ),
                                      ),
                                      TextSpan(
                                        text: "Listem",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w300,
                                          color: Color(0xFF0A0E14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Gorev Ekleme Butonu
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.buttonGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _showAddTaskDialog,
                                  borderRadius: BorderRadius.circular(12),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          color: Color(0xFF0A0E14),
                                          size: 20,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          "Görev Ekle",
                                          style: TextStyle(
                                            color: Color(0xFF0A0E14),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Logout
                            IconButton(
                              onPressed: _showLogoutDialog,
                              icon: const Icon(
                                Icons.logout,
                                color: Color(0xFF0A0E14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Progress Bar (Placeholder)
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService.getTasksStream(_userId),
                      builder: (context, snapshot) {
                        int totalTasks = 0;
                        int completedTasks = 0;

                        if (snapshot.hasData) {
                          final tasks = snapshot.data!.docs;
                          totalTasks = tasks.length;
                          for (var doc in tasks) {
                            final task = doc.data() as Map<String, dynamic>;
                            if (task['isDone'] == true) completedTasks++;
                          }
                        }

                        double progress = totalTasks > 0
                            ? completedTasks / totalTasks
                            : 0;
                        int percentage = (progress * 100).round();

                        return Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "$totalTasks görev • $completedTasks tamamlandı",
                                  style: const TextStyle(
                                    color: Color(0xFF0A0E14),
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  "%$percentage",
                                  style: const TextStyle(
                                    color: Color(0xFF0A0E14),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: const Color(
                                  0xFF0A0E14,
                                ).withValues(alpha: 0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0A0E14),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Kategori Filtreleri
            SliverToBoxAdapter(
              child: Container(
                height: 50,
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Tumu butonu
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text("Tümü"),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                        backgroundColor: cardColor,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: _selectedCategory == null
                              ? Colors.white
                              : textPrimary,
                        ),
                      ),
                    ),
                    // Kategori butonlari
                    ...Category.values.map((category) {
                      final info = categoryInfo[category]!;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(
                            info['icon'] as IconData,
                            size: 18,
                            color: _selectedCategory == category
                                ? Colors.white
                                : info['color'] as Color,
                          ),
                          label: Text(info['name'] as String),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : null;
                            });
                          },
                          backgroundColor: cardColor,
                          selectedColor: info['color'] as Color,
                          labelStyle: TextStyle(
                            color: _selectedCategory == category
                                ? Colors.white
                                : textPrimary,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Offline gostergesi
            if (_isOffline)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Çevrimdışı mod - Cache'den gösteriliyor",
                          style: TextStyle(
                            color: Colors.orange.shade200,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Gorev Listesi
            StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getTasksStream(_userId),
              builder: (context, snapshot) {
                // Hata durumunda cache'den goster
                if (snapshot.hasError) {
                  _loadCachedTasks();
                  if (_cachedTasks.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_isOffline) {
                        setState(() => _isOffline = true);
                      }
                    });
                    return _buildCachedTaskList();
                  }
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Beklerken cache'den goster
                  if (_cachedTasks.isNotEmpty) {
                    return _buildCachedTaskList();
                  }
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }

                // Online durumda cache'i guncelle
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _isOffline) {
                      setState(() => _isOffline = false);
                    }
                  });
                  _cacheTasks(snapshot.data!.docs);
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.task_alt,
                            size: 80,
                            color: textSecondary.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Henüz görev yok",
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Yeni görev eklemek için + butonuna basın",
                            style: TextStyle(
                              color: textSecondary.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var tasks = snapshot.data!.docs;

                // Kategori filtresi uygula
                if (_selectedCategory != null) {
                  tasks = tasks.where((doc) {
                    final task = doc.data() as Map<String, dynamic>;
                    return task['category'] == _selectedCategory!.name;
                  }).toList();
                }

                if (tasks.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        "Bu kategoride görev yok",
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final doc = tasks[index];
                      final task = doc.data() as Map<String, dynamic>;
                      final taskId = doc.id;
                      final isDone = task['isDone'] ?? false;
                      final priority = task['priority'] as String?;
                      final categoryStr = task['category'] as String?;
                      final endDateTimestamp = task['endDate'] as Timestamp?;
                      final endDate = endDateTimestamp?.toDate();
                      final isExpired = _isExpired(endDate) && !isDone;

                      Category? taskCategory;
                      if (categoryStr != null) {
                        try {
                          taskCategory = Category.values.firstWhere(
                            (c) => c.name == categoryStr,
                          );
                        } catch (_) {}
                      }

                      return Dismissible(
                        key: Key(taskId),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: context.padding.onlyBottomLow,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: context.border.lowBorderRadius,
                          ),
                          alignment: Alignment.centerRight,
                          padding: context.padding.onlyRightNormal,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          _firestoreService.deleteTask(_userId, taskId);
                        },
                        child: InkWell(
                          onTap: () => _showTaskDetailDialog(task, taskId),
                          borderRadius: context.border.normalBorderRadius,
                          child: Container(
                            margin: context.padding.onlyBottomLow,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: context.border.normalBorderRadius,
                              border: Border.all(
                                color: isExpired
                                    ? Colors.red.withValues(alpha: 0.5)
                                    : AppTheme.borderColor,
                                width: isExpired ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: context.padding.low,
                              leading: GestureDetector(
                                onTap: () {
                                  _firestoreService.toggleTaskStatus(
                                    _userId,
                                    taskId,
                                    !isDone,
                                  );
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDone
                                        ? AppTheme.primaryColor
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isDone
                                          ? AppTheme.primaryColor
                                          : _getPriorityColor(priority),
                                      width: 2,
                                    ),
                                  ),
                                  child: isDone
                                      ? const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              title: Text(
                                task['title'] ?? '',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w600,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task['description'] != null &&
                                      task['description'].isNotEmpty)
                                    Text(
                                      task['description'],
                                      style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      // Kategori
                                      if (taskCategory != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (categoryInfo[taskCategory]!['color']
                                                        as Color)
                                                    .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                categoryInfo[taskCategory]!['icon']
                                                    as IconData,
                                                size: 12,
                                                color:
                                                    categoryInfo[taskCategory]!['color']
                                                        as Color,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                categoryInfo[taskCategory]!['name']
                                                    as String,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      categoryInfo[taskCategory]!['color']
                                                          as Color,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      // Bitis tarihi
                                      if (endDate != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isExpired
                                                ? Colors.red.withValues(
                                                    alpha: 0.2,
                                                  )
                                                : AppTheme.primaryColor
                                                      .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.event,
                                                size: 12,
                                                color: isExpired
                                                    ? Colors.red
                                                    : AppTheme.primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat(
                                                  'dd/MM',
                                                ).format(endDate),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isExpired
                                                      ? Colors.red
                                                      : AppTheme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Düzenle butonu
                                  IconButton(
                                    onPressed: () =>
                                        _showEditTaskDialog(task, taskId),
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: textSecondary,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _confirmDeleteTask(taskId),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 32,
                                      minHeight: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Öncelik etiketi
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPriorityColor(
                                        priority,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getPriorityText(priority),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _getPriorityColor(priority),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: tasks.length),
                  ),
                );
              },
            ),

            // Alt bosluk
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}
