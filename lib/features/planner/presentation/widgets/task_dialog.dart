import 'package:flutter/material.dart';
import '../../domain/models/planner_task.dart';
import 'package:uuid/uuid.dart';

/// Диалог для добавления/редактирования задачи
class TaskDialog extends StatefulWidget {
  final PlannerTask? task; // null = создание новой задачи
  final DateTime? initialTime; // Начальное время для новой задачи

  const TaskDialog({
    super.key,
    this.task,
    this.initialTime,
  });

  @override
  State<TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskType _taskType;
  late DateTime _startTime;
  DateTime? _endTime;
  Color _selectedColor = Colors.blue;

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.pink,
    Colors.indigo,
    Colors.teal,
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.task != null) {
      // Редактирование существующей задачи
      _titleController = TextEditingController(text: widget.task!.title);
      _descriptionController =
          TextEditingController(text: widget.task!.description ?? '');
      _taskType = widget.task!.type;
      _startTime = widget.task!.startTime;
      _endTime = widget.task!.endTime;
      _selectedColor = widget.task!.color ?? Colors.blue;
    } else {
      // Создание новой задачи
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _taskType = TaskType.point;
      _startTime = widget.initialTime ?? DateTime.now();
      _endTime = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime),
      );

      if (time != null) {
        setState(() {
          _startTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    if (_taskType != TaskType.interval) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime,
      firstDate: _startTime,
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime ?? _startTime),
      );

      if (time != null) {
        final selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        if (selectedDateTime.isAfter(_startTime)) {
          setState(() {
            _endTime = selectedDateTime;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Время окончания должно быть позже времени начала'),
            ),
          );
        }
      }
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      if (_taskType == TaskType.interval && _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Для интервальной задачи необходимо указать время окончания'),
          ),
        );
        return;
      }

      final task = PlannerTask(
        id: widget.task?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        type: _taskType,
        startTime: _startTime,
        endTime: _endTime,
        isCompleted: widget.task?.isCompleted ?? false,
        color: _selectedColor,
      );

      Navigator.of(context).pop(task);
    }
  }

  void _deleteTask() {
    Navigator.of(context).pop({'action': 'delete'});
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return AlertDialog(
      title: Text(isEditing ? 'Редактировать задачу' : 'Новая задача'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Название
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название задачи';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Описание
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Тип задачи
              DropdownButtonFormField<TaskType>(
                value: _taskType,
                decoration: const InputDecoration(
                  labelText: 'Тип задачи',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TaskType.point,
                    child: Text('Точечная'),
                  ),
                  DropdownMenuItem(
                    value: TaskType.interval,
                    child: Text('Интервальная'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _taskType = value!;
                    if (_taskType == TaskType.point) {
                      _endTime = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Время начала
              ListTile(
                title: const Text('Время начала'),
                subtitle: Text(
                  '${_startTime.day}.${_startTime.month}.${_startTime.year} ${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _selectStartTime,
              ),

              // Время окончания (только для интервальных)
              if (_taskType == TaskType.interval) ...[
                ListTile(
                  title: const Text('Время окончания'),
                  subtitle: Text(
                    _endTime != null
                        ? '${_endTime!.day}.${_endTime!.month}.${_endTime!.year} ${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
                        : 'Не выбрано',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectEndTime,
                ),
              ],

              const SizedBox(height: 16),

              // Цвет
              const Text('Цвет:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedColor == color
                              ? Colors.black
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (isEditing)
          TextButton(
            onPressed: _deleteTask,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _saveTask,
          child: Text(isEditing ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}

