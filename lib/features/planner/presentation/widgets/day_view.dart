import 'package:flutter/material.dart';
import '../../domain/models/planner_task.dart';
import 'task_card.dart';

/// Элемент списка: задача или маркер (время, свободное время)
abstract class DayListItem {
  final String id;
  DayListItem({required this.id});
}

/// Задача в списке
class TaskItem extends DayListItem {
  final PlannerTask task;
  final bool isNested;
  final PlannerTask? parentTask;

  TaskItem({
    required super.id,
    required this.task,
    this.isNested = false,
    this.parentTask,
  });
}

/// Маркер текущего времени
class CurrentTimeMarker extends DayListItem {
  final DateTime time;

  CurrentTimeMarker({
    required super.id,
    required this.time,
  });
}

/// Свободное время между задачами
class FreeTimeSlot extends DayListItem {
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;

  FreeTimeSlot({
    required super.id,
    required this.startTime,
    required this.endTime,
  }) : duration = endTime.difference(startTime);
}

/// Виджет дня со списком задач
class DayView extends StatefulWidget {
  /// Дата для отображения
  final DateTime date;

  /// Список задач на этот день
  final List<PlannerTask> tasks;

  /// Callback при клике на задачу
  final Function(PlannerTask) onTaskTap;

  /// Callback при клике на пустое место (свободное время)
  final Function(DateTime) onTimeSlotTap;

  /// Callback при долгом нажатии на задачу (для переключения статуса)
  final Function(PlannerTask)? onTaskLongPress;

  const DayView({
    super.key,
    required this.date,
    required this.tasks,
    required this.onTaskTap,
    required this.onTimeSlotTap,
    this.onTaskLongPress,
  });

  @override
  State<DayView> createState() => _DayViewState();
}

class _DayViewState extends State<DayView> {
  // Таймер для обновления текущего времени
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    // Обновляем текущее время каждую минуту
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
        _startTimer();
      }
    });
  }

  /// Проверяет, попадает ли точечная задача в интервал интервальной задачи
  bool _isPointTaskInsideInterval(PlannerTask pointTask, PlannerTask intervalTask) {
    if (intervalTask.endTime == null) return false;

    final pointTime = pointTask.startTime;
    final intervalStart = intervalTask.startTime;
    final intervalEnd = intervalTask.endTime!;

    return (pointTime.isAfter(intervalStart) || pointTime.isAtSameMomentAs(intervalStart)) &&
           (pointTime.isBefore(intervalEnd) || pointTime.isAtSameMomentAs(intervalEnd));
  }

  /// Форматирует время для отображения
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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

  /// Строит список элементов для отображения (задачи, маркеры времени, свободное время)
  List<DayListItem> _buildListItems() {
    final items = <DayListItem>[];

    // Разделяем задачи на интервальные и точечные
    final intervalTasks = <PlannerTask>[];
    final pointTasks = <PlannerTask>[];

    for (final task in widget.tasks) {
      if (task.type == TaskType.interval) {
        intervalTasks.add(task);
      } else {
        pointTasks.add(task);
      }
    }

    // Сортируем задачи по времени начала
    intervalTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
    pointTasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Группируем точечные задачи по интервальным
    final pointTasksByInterval = <String, List<PlannerTask>>{};
    final standalonePoints = <PlannerTask>[];

    for (final pointTask in pointTasks) {
      bool foundParent = false;
      for (final intervalTask in intervalTasks) {
        if (_isPointTaskInsideInterval(pointTask, intervalTask)) {
          if (!pointTasksByInterval.containsKey(intervalTask.id)) {
            pointTasksByInterval[intervalTask.id] = [];
          }
          pointTasksByInterval[intervalTask.id]!.add(pointTask);
          foundParent = true;
          break;
        }
      }
      if (!foundParent) {
        standalonePoints.add(pointTask);
      }
    }

    // Сортируем вложенные точечные задачи по времени
    for (final key in pointTasksByInterval.keys) {
      pointTasksByInterval[key]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    // Объединяем все задачи в один список для сортировки
    final allTasksWithNested = <TaskItem>[];

    // Добавляем интервальные задачи с вложенными точечными
    for (final intervalTask in intervalTasks) {
      allTasksWithNested.add(TaskItem(
        id: intervalTask.id,
        task: intervalTask,
      ));

      // Добавляем вложенные точечные задачи сразу после интервальной
      if (pointTasksByInterval.containsKey(intervalTask.id)) {
        for (final nestedPoint in pointTasksByInterval[intervalTask.id]!) {
          allTasksWithNested.add(TaskItem(
            id: '${intervalTask.id}_nested_${nestedPoint.id}',
            task: nestedPoint,
            isNested: true,
            parentTask: intervalTask,
          ));
        }
      }
    }

    // Добавляем самостоятельные точечные задачи
    for (final pointTask in standalonePoints) {
      allTasksWithNested.add(TaskItem(
        id: pointTask.id,
        task: pointTask,
      ));
    }

    // Сортируем все задачи по времени
    allTasksWithNested.sort((a, b) => a.task.startTime.compareTo(b.task.startTime));

    // Начало дня
    final dayStart = DateTime(widget.date.year, widget.date.month, widget.date.day, 0, 0);
    final dayEnd = DateTime(widget.date.year, widget.date.month, widget.date.day, 23, 59, 59);

    // Добавляем элементы в список
    DateTime? lastEndTime = dayStart;

    for (final taskItem in allTasksWithNested) {
      final task = taskItem.task;
      final taskStart = task.startTime;
      final taskEnd = task.endTime ?? task.startTime.add(const Duration(minutes: 1));

      // Проверяем, нужно ли добавить маркер текущего времени
      final isToday = _currentTime.year == widget.date.year &&
          _currentTime.month == widget.date.month &&
          _currentTime.day == widget.date.day;

      if (isToday &&
          lastEndTime != null &&
          _currentTime.isAfter(lastEndTime) &&
          _currentTime.isBefore(taskStart)) {
        items.add(CurrentTimeMarker(
          id: 'current_time_${_currentTime.millisecondsSinceEpoch}',
          time: _currentTime,
        ));
        lastEndTime = _currentTime;
      }

      // Добавляем свободное время перед задачей (если есть)
      if (lastEndTime != null && taskStart.isAfter(lastEndTime!)) {
        final freeTimeStart = lastEndTime!;
        final freeTimeEnd = taskStart;
        final freeDuration = freeTimeEnd.difference(freeTimeStart);

        // Показываем свободное время только если оно больше 15 минут
        if (freeDuration.inMinutes >= 15) {
          items.add(FreeTimeSlot(
            id: 'free_${freeTimeStart.millisecondsSinceEpoch}',
            startTime: freeTimeStart,
            endTime: freeTimeEnd,
          ));
        }
      }

      // Добавляем саму задачу
      items.add(taskItem);

      // Обновляем последнее время окончания (не для вложенных задач)
      if (!taskItem.isNested) {
        lastEndTime = taskEnd;
      }
    }

    // Проверяем, нужно ли добавить маркер текущего времени после последней задачи
    final isToday = _currentTime.year == widget.date.year &&
        _currentTime.month == widget.date.month &&
        _currentTime.day == widget.date.day;

    if (isToday &&
        lastEndTime != null &&
        _currentTime.isAfter(lastEndTime!)) {
      items.add(CurrentTimeMarker(
        id: 'current_time_end',
        time: _currentTime,
      ));
      lastEndTime = _currentTime;
    }

    // Добавляем свободное время в конце дня (если есть)
    if (lastEndTime != null && dayEnd.isAfter(lastEndTime!)) {
      final freeDuration = dayEnd.difference(lastEndTime!);
      if (freeDuration.inMinutes >= 15) {
        items.add(FreeTimeSlot(
          id: 'free_${lastEndTime!.millisecondsSinceEpoch}',
          startTime: lastEndTime!,
          endTime: dayEnd,
        ));
      }
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildListItems();

    return Column(
      children: [
        // Заголовок с датой
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(widget.date),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                _getDayName(widget.date),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
        // Список задач
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет задач на этот день',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    if (item is CurrentTimeMarker) {
                      return _buildCurrentTimeMarker(context, item);
                    } else if (item is FreeTimeSlot) {
                      return _buildFreeTimeSlot(context, item);
                    } else if (item is TaskItem) {
                      return _buildTaskItem(context, item);
                    }

                    return const SizedBox.shrink();
                  },
                ),
        ),
      ],
    );
  }

  /// Строит виджет маркера текущего времени
  Widget _buildCurrentTimeMarker(BuildContext context, CurrentTimeMarker marker) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.access_time,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'Сейчас: ${_formatTime(marker.time)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Строит виджет свободного времени
  Widget _buildFreeTimeSlot(BuildContext context, FreeTimeSlot freeTime) {
    return GestureDetector(
      onTap: () => widget.onTimeSlotTap(freeTime.startTime),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Свободное время',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(freeTime.startTime)} - ${_formatTime(freeTime.endTime)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Text(
                _formatDuration(freeTime.duration),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Строит виджет задачи
  Widget _buildTaskItem(BuildContext context, TaskItem taskItem) {
    return Padding(
      padding: EdgeInsets.only(
        left: taskItem.isNested ? 24 : 0,
        top: 8,
        bottom: 8,
      ),
      child: TaskCard(
        task: taskItem.task,
        onTap: widget.onTaskTap,
        onLongPress: widget.onTaskLongPress,
        isNested: taskItem.isNested,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Января',
      'Февраля',
      'Марта',
      'Апреля',
      'Мая',
      'Июня',
      'Июля',
      'Августа',
      'Сентября',
      'Октября',
      'Ноября',
      'Декабря',
    ];
    return '${date.day} ${date.month < 13 ? months[date.month - 1] : ''} ${date.year}';
  }

  String _getDayName(DateTime date) {
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    return days[date.weekday - 1];
  }
}
