import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../domain/models/planner_task.dart';

/// Модель задачи для хранения в Hive
@HiveType(typeId: 0)
class PlannerTaskHive extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int typeIndex; // 0 = point, 1 = interval

  @HiveField(4)
  DateTime startTime;

  @HiveField(5)
  DateTime? endTime;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  int? colorValue; // ARGB значение цвета

  PlannerTaskHive({
    required this.id,
    required this.title,
    this.description,
    required this.typeIndex,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.colorValue,
  });

  /// Преобразует PlannerTaskHive в PlannerTask
  PlannerTask toDomain() {
    return PlannerTask(
      id: id,
      title: title,
      description: description,
      type: typeIndex == 0 ? TaskType.point : TaskType.interval,
      startTime: startTime,
      endTime: endTime,
      isCompleted: isCompleted,
      color: colorValue != null ? Color(colorValue!) : null,
    );
  }

  /// Создает PlannerTaskHive из PlannerTask
  factory PlannerTaskHive.fromDomain(PlannerTask task) {
    return PlannerTaskHive(
      id: task.id,
      title: task.title,
      description: task.description,
      typeIndex: task.type == TaskType.point ? 0 : 1,
      startTime: task.startTime,
      endTime: task.endTime,
      isCompleted: task.isCompleted,
      colorValue: task.color?.value,
    );
  }
}

