import 'package:flutter/material.dart';

/// Тип задачи: точечная или интервальная
enum TaskType {
  /// Точечная задача - один момент времени
  point,

  /// Интервальная задача - временной диапазон
  interval,
}

/// Модель задачи планировщика
class PlannerTask {
  /// Уникальный идентификатор задачи
  final String id;

  /// Название задачи
  final String title;

  /// Описание задачи (опционально)
  final String? description;

  /// Тип задачи: точечная или интервальная
  final TaskType type;

  /// Время начала задачи
  final DateTime startTime;

  /// Время окончания задачи (только для интервальных)
  final DateTime? endTime;

  /// Статус выполнения задачи
  final bool isCompleted;

  /// Цвет задачи для визуализации
  final Color? color;

  /// Дата задачи (без времени)
  DateTime get date => DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
      );

  /// Проверяет, является ли задача прошедшей
  bool get isPast {
    final now = DateTime.now();
    final taskEndTime = endTime ?? startTime;
    return taskEndTime.isBefore(now);
  }

  /// Проверяет, является ли задача текущей
  bool get isCurrent {
    final now = DateTime.now();
    final taskEndTime = endTime ?? startTime;
    return startTime.isBefore(now) || startTime.isAtSameMomentAs(now) &&
        (taskEndTime.isAfter(now) || taskEndTime.isAtSameMomentAs(now));
  }

  /// Проверяет, является ли задача будущей
  bool get isFuture {
    return startTime.isAfter(DateTime.now());
  }

  /// Проверяет, пересекается ли задача с другой задачей
  bool overlapsWith(PlannerTask other) {
    if (type == TaskType.point && other.type == TaskType.point) {
      // Две точечные задачи не могут пересекаться
      return false;
    }

    final thisStart = startTime;
    final thisEnd = endTime ?? startTime.add(const Duration(minutes: 1));
    final otherStart = other.startTime;
    final otherEnd = other.endTime ?? other.startTime.add(const Duration(minutes: 1));

    // Проверка пересечения интервалов
    return thisStart.isBefore(otherEnd) && thisEnd.isAfter(otherStart);
  }

  PlannerTask({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.color,
  }) : assert(
          type == TaskType.point || endTime != null,
          'Интервальная задача должна иметь endTime',
        ),
         assert(
          type == TaskType.interval && endTime != null
              ? endTime!.isAfter(startTime)
              : true,
          'endTime должна быть позже startTime',
        );

  /// Создает копию задачи с обновленными полями
  PlannerTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? type,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    Color? color,
  }) {
    return PlannerTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      color: color ?? this.color,
    );
  }
}

