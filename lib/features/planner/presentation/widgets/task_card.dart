import 'package:flutter/material.dart';
import '../../domain/models/planner_task.dart';

/// Карточка задачи для отображения в списке
class TaskCard extends StatelessWidget {
  final PlannerTask task;
  final Function(PlannerTask) onTap;
  final Function(PlannerTask)? onLongPress;
  final bool isNested;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    this.onLongPress,
    this.isNested = false,
  });

  /// Форматирует время
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPast = task.isPast;
    final isCompleted = task.isCompleted;

    // Определяем цвет задачи
    Color taskColor = task.color ?? theme.colorScheme.primary;
    if (isCompleted) {
      taskColor = Colors.green;
    } else if (isPast) {
      taskColor = Colors.grey[600] ?? Colors.grey;
    }

    // Для вложенных точечных задач используем более светлый стиль
    if (isNested) {
      return GestureDetector(
        onTap: () => onTap(task),
        onLongPress: onLongPress != null ? () => onLongPress!(task) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: taskColor.withOpacity(0.08),
            border: Border(
              left: BorderSide(
                color: taskColor,
                width: 3,
              ),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Иконка для точечной задачи
              Icon(
                Icons.radio_button_checked,
                size: 16,
                color: taskColor,
              ),
              const SizedBox(width: 12),
              // Контент задачи
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isPast && !isCompleted
                                  ? Colors.grey[600]
                                  : theme.colorScheme.onSurface,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          const Icon(Icons.check_circle, size: 16, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(task.startTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: isPast && !isCompleted
                            ? Colors.grey[500]
                            : Colors.grey[600],
                      ),
                    ),
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        task.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Обычная задача (интервальная или самостоятельная точечная)
    final timeText = task.type == TaskType.interval && task.endTime != null
        ? '${_formatTime(task.startTime)} - ${_formatTime(task.endTime!)}'
        : _formatTime(task.startTime);

    final durationText = task.type == TaskType.interval && task.endTime != null
        ? _formatDuration(task.endTime!.difference(task.startTime))
        : null;

    return GestureDetector(
      onTap: () => onTap(task),
      onLongPress: onLongPress != null ? () => onLongPress!(task) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: taskColor.withOpacity(0.15),
          border: Border(
            left: BorderSide(
              color: taskColor,
              width: 4,
            ),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Иконка типа задачи
                Icon(
                  task.type == TaskType.interval
                      ? Icons.event_note
                      : Icons.radio_button_checked,
                  size: 20,
                  color: taskColor,
                ),
                const SizedBox(width: 12),
                // Название задачи
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isPast && !isCompleted
                          ? Colors.grey[600]
                          : theme.colorScheme.onSurface,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                // Иконка статуса
                if (isCompleted)
                  const Icon(Icons.check_circle, size: 20, color: Colors.green)
                else if (isPast)
                  Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
              ],
            ),
            const SizedBox(height: 8),
            // Время и длительность
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 14,
                    color: isPast && !isCompleted
                        ? Colors.grey[500]
                        : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (durationText != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '($durationText)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            // Описание
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Форматирует длительность
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours ч $minutes мин';
    } else if (hours > 0) {
      return '$hours ч';
    } else if (minutes > 0) {
      return '$minutes мин';
    } else {
      return 'Меньше минуты';
    }
  }
}
