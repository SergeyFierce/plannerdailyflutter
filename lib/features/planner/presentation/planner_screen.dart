import 'package:flutter/material.dart';
import '../domain/models/planner_task.dart';
import '../data/planner_repository.dart';
import 'widgets/calendar_view.dart';
import 'widgets/day_view.dart';
import 'widgets/task_dialog.dart';

/// Главный экран планировщика
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  /// Выбранная дата для просмотра дня
  DateTime? _selectedDate;

  /// Текущий отображаемый месяц в календаре
  DateTime _currentMonth = DateTime.now();

  /// Все задачи (для календаря)
  List<PlannerTask> _allTasks = [];

  /// Задачи для выбранного дня
  List<PlannerTask> _dayTasks = [];

  /// Репозиторий для работы с БД
  final PlannerRepository _repository = PlannerRepository();

  /// Флаг загрузки
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllTasks();
  }

  /// Загружает все задачи из БД
  Future<void> _loadAllTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _repository.getAllTasks();
      setState(() {
        _allTasks = tasks;
        if (_selectedDate != null) {
          _loadDayTasks(_selectedDate!);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки задач: $e')),
        );
      }
    }
  }

  /// Загружает задачи для конкретного дня
  Future<void> _loadDayTasks(DateTime date) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _repository.getTasksForDay(date);
      setState(() {
        _dayTasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки задач: $e')),
        );
      }
    }
  }

  /// Обработчик выбора даты в календаре
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadDayTasks(date);
  }

  /// Обработчик возврата к календарю
  void _onBackToCalendar() {
    setState(() {
      _selectedDate = null;
      _dayTasks = [];
    });
    _loadAllTasks(); // Обновляем календарь
  }

  /// Обработчик клика на задачу
  Future<void> _onTaskTap(PlannerTask task) async {
    final result = await showDialog(
      context: context,
      builder: (context) => TaskDialog(task: task),
    );

    if (result != null) {
      if (result is Map && result['action'] == 'delete') {
        // Удаление задачи
        await _deleteTask(task);
      } else if (result is PlannerTask) {
        // Редактирование задачи
        await _updateTask(result);
      }
    }
  }

  /// Обработчик клика на временной слот (свободное время)
  Future<void> _onTimeSlotTap(DateTime time) async {
    final result = await showDialog(
      context: context,
      builder: (context) => TaskDialog(initialTime: time),
    );

    if (result is PlannerTask) {
      await _addTask(result);
    }
  }

  /// Добавляет новую задачу
  Future<void> _addTask(PlannerTask task) async {
    try {
      await _repository.addTask(task);
      await _loadAllTasks(); // Обновляем все задачи
      if (_selectedDate != null) {
        await _loadDayTasks(_selectedDate!); // Обновляем задачи дня
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача добавлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка добавления задачи: $e')),
        );
      }
    }
  }

  /// Обновляет задачу
  Future<void> _updateTask(PlannerTask task) async {
    try {
      await _repository.updateTask(task);
      await _loadAllTasks(); // Обновляем все задачи
      if (_selectedDate != null) {
        await _loadDayTasks(_selectedDate!); // Обновляем задачи дня
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача обновлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления задачи: $e')),
        );
      }
    }
  }

  /// Удаляет задачу
  Future<void> _deleteTask(PlannerTask task) async {
    try {
      await _repository.deleteTask(task.id);
      await _loadAllTasks(); // Обновляем все задачи
      if (_selectedDate != null) {
        await _loadDayTasks(_selectedDate!); // Обновляем задачи дня
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Задача удалена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления задачи: $e')),
        );
      }
    }
  }

  /// Переключает статус выполнения задачи
  Future<void> _toggleTaskComplete(PlannerTask task) async {
    try {
      await _repository.toggleComplete(task.id, !task.isCompleted);
      await _loadAllTasks(); // Обновляем все задачи
      if (_selectedDate != null) {
        await _loadDayTasks(_selectedDate!); // Обновляем задачи дня
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления статуса: $e')),
        );
      }
    }
  }

  /// Обработчик смены месяца в календаре
  void _onMonthChanged(DateTime month) {
    setState(() {
      _currentMonth = month;
    });
  }

  /// Обработчик добавления новой задачи
  Future<void> _onAddTask() async {
    final result = await showDialog(
      context: context,
      builder: (context) => TaskDialog(
        initialTime: _selectedDate ?? DateTime.now(),
      ),
    );

    if (result is PlannerTask) {
      await _addTask(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedDate == null ? 'Календарь' : 'Планировщик дня'),
        centerTitle: false,
        leading: _selectedDate != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _onBackToCalendar,
              )
            : null,
        actions: [
          // Кнопка добавления задачи
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAddTask,
            tooltip: 'Добавить задачу',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedDate == null
              ? CalendarView(
                  selectedDate: DateTime.now(),
                  allTasks: _allTasks,
                  onDateSelected: _onDateSelected,
                  currentMonth: _currentMonth,
                  onMonthChanged: _onMonthChanged,
                )
              : DayView(
                  date: _selectedDate!,
                  tasks: _dayTasks,
                  onTaskTap: _onTaskTap,
                  onTimeSlotTap: _onTimeSlotTap,
                  onTaskLongPress: _toggleTaskComplete,
                ),
      // Floating action button для быстрого добавления задачи (в режиме дня)
      floatingActionButton: _selectedDate != null
          ? FloatingActionButton(
              onPressed: _onAddTask,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
