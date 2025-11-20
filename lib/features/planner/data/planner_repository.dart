import 'package:hive_flutter/hive_flutter.dart';
import '../domain/models/planner_task.dart';
import 'models/planner_task_hive.dart';

/// Репозиторий для работы с задачами планировщика в БД
class PlannerRepository {
  static const String _boxName = 'planner_tasks';
  static Box<PlannerTaskHive>? _box;

  /// Инициализация репозитория и открытие БД
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Регистрируем адаптер для PlannerTaskHive
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(PlannerTaskHiveAdapter());
    }

    // Открываем бокс для хранения задач
    _box = await Hive.openBox<PlannerTaskHive>(_boxName);
  }

  /// Получает задачи для конкретного дня
  Future<List<PlannerTask>> getTasksForDay(DateTime day) async {
    if (_box == null) await init();

    final dayStart = DateTime(day.year, day.month, day.day, 0, 0);
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59);

    final tasks = <PlannerTask>[];

    for (var i = 0; i < _box!.length; i++) {
      final taskHive = _box!.getAt(i);
      if (taskHive != null) {
        final task = taskHive.toDomain();
        final taskDate = task.date;
        if (taskDate.year == day.year &&
            taskDate.month == day.month &&
            taskDate.day == day.day) {
          tasks.add(task);
        }
      }
    }

    return tasks;
  }

  /// Получает все задачи (для календаря)
  Future<List<PlannerTask>> getAllTasks() async {
    if (_box == null) await init();

    final tasks = <PlannerTask>[];

    for (var i = 0; i < _box!.length; i++) {
      final taskHive = _box!.getAt(i);
      if (taskHive != null) {
        tasks.add(taskHive.toDomain());
      }
    }

    return tasks;
  }

  /// Добавляет новую задачу
  Future<void> addTask(PlannerTask task) async {
    if (_box == null) await init();

    final taskHive = PlannerTaskHive.fromDomain(task);
    await _box!.add(taskHive);
  }

  /// Обновляет существующую задачу
  Future<void> updateTask(PlannerTask task) async {
    if (_box == null) await init();

    // Находим задачу по ID
    for (var i = 0; i < _box!.length; i++) {
      final taskHive = _box!.getAt(i);
      if (taskHive != null && taskHive.id == task.id) {
        final updatedTask = PlannerTaskHive.fromDomain(task);
        await _box!.putAt(i, updatedTask);
        return;
      }
    }
  }

  /// Удаляет задачу по ID
  Future<void> deleteTask(String id) async {
    if (_box == null) await init();

    // Находим задачу по ID и удаляем
    for (var i = 0; i < _box!.length; i++) {
      final taskHive = _box!.getAt(i);
      if (taskHive != null && taskHive.id == id) {
        await _box!.deleteAt(i);
        return;
      }
    }
  }

  /// Переключает статус выполнения задачи
  Future<void> toggleComplete(String id, bool isCompleted) async {
    if (_box == null) await init();

    // Находим задачу по ID и обновляем статус
    for (var i = 0; i < _box!.length; i++) {
      final taskHive = _box!.getAt(i);
      if (taskHive != null && taskHive.id == id) {
        taskHive.isCompleted = isCompleted;
        await _box!.putAt(i, taskHive);
        return;
      }
    }
  }
}

/// Адаптер для Hive (простая реализация без code generation)
class PlannerTaskHiveAdapter extends TypeAdapter<PlannerTaskHive> {
  @override
  final int typeId = 0;

  @override
  PlannerTaskHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    return PlannerTaskHive(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      typeIndex: fields[3] as int,
      startTime: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      endTime: fields[5] != null
          ? DateTime.fromMillisecondsSinceEpoch(fields[5] as int)
          : null,
      isCompleted: fields[6] as bool,
      colorValue: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PlannerTaskHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.typeIndex)
      ..writeByte(4)
      ..write(obj.startTime.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.endTime?.millisecondsSinceEpoch)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannerTaskHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

