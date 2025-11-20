import 'package:flutter/material.dart';
import '../../domain/models/planner_task.dart';

/// Виджет календаря для выбора дня
class CalendarView extends StatelessWidget {
  /// Выбранный день
  final DateTime selectedDate;

  /// Список всех задач для индикации в календаре
  final List<PlannerTask> allTasks;

  /// Callback при выборе дня
  final Function(DateTime) onDateSelected;

  /// Текущий отображаемый месяц
  final DateTime currentMonth;

  /// Callback при смене месяца
  final Function(DateTime) onMonthChanged;

  const CalendarView({
    super.key,
    required this.selectedDate,
    required this.allTasks,
    required this.onDateSelected,
    required this.currentMonth,
    required this.onMonthChanged,
  });

  /// Получает задачи для конкретной даты
  List<PlannerTask> _getTasksForDate(DateTime date) {
    return allTasks.where((task) {
      final taskDate = task.date;
      return taskDate.year == date.year &&
          taskDate.month == date.month &&
          taskDate.day == date.day;
    }).toList();
  }

  /// Проверяет, все ли задачи выполнены для даты
  bool _areAllTasksCompleted(DateTime date) {
    final tasks = _getTasksForDate(date);
    if (tasks.isEmpty) return false;
    return tasks.every((task) => task.isCompleted);
  }

  /// Проверяет, есть ли задачи для даты
  bool _hasTasks(DateTime date) {
    return _getTasksForDate(date).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    // Определяем первый день месяца и количество дней
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // День недели первого дня месяца (1 = понедельник, 7 = воскресенье)
    int firstWeekday = firstDayOfMonth.weekday;
    // Преобразуем к формату: 0 = понедельник, 6 = воскресенье
    firstWeekday = firstWeekday == 7 ? 0 : firstWeekday;

    // Названия дней недели
    const weekdays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Column(
      children: [
        // Заголовок с месяцем и навигацией
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final previousMonth =
                      DateTime(currentMonth.year, currentMonth.month - 1);
                  onMonthChanged(previousMonth);
                },
              ),
              Text(
                _getMonthName(currentMonth),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final nextMonth =
                      DateTime(currentMonth.year, currentMonth.month + 1);
                  onMonthChanged(nextMonth);
                },
              ),
            ],
          ),
        ),
        // Заголовки дней недели
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: weekdays.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Ячейки календаря
        Expanded(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: firstWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < firstWeekday) {
                // Пустая ячейка до начала месяца
                return const SizedBox.shrink();
              }

              final day = index - firstWeekday + 1;
              final date = DateTime(currentMonth.year, currentMonth.month, day);
              final isSelected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;
              final hasTasks = _hasTasks(date);
              final allCompleted = _areAllTasksCompleted(date);

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : isToday
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                    border: isToday && !isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Число дня
                      Text(
                        '$day',
                        style: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : isToday
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : null,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      // Индикатор задач внизу
                      if (hasTasks)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: allCompleted
                                  ? Colors.green
                                  : isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withOpacity(0.8)
                                      : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return months[date.month - 1];
  }
}

