import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Нужен для получения текущей даты (добавьте в pubspec.yaml)
import 'database_helper.dart'; // Импорт вашего файла с кодом

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({Key? key}) : super(key: key);

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  // Получаем текущую дату в формате YYYY-MM-DD, как в вашей БД
  final String _today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  
  List<Habit> _habits = [];
  List<int> _completedTodayIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Загружаем из БД и привычки, и отметки за сегодня
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final habits = await DatabaseHelper.instance.getHabits();
    final completedIds = await DatabaseHelper.instance.getCompletedHabitIdsForDate(_today);
    
    setState(() {
      _habits = habits;
      _completedTodayIds = completedIds;
      _isLoading = false;
    });
  }

  // Переключение статуса выполнения
  Future<void> _onToggleHabit(int habitId) async {
    await DatabaseHelper.instance.toggleCompletion(habitId, _today);
    // Обновляем только локальный список отметок, чтобы UI изменился мгновенно
    setState(() {
      if (_completedTodayIds.contains(habitId)) {
        _completedTodayIds.remove(habitId);
      } else {
        _completedTodayIds.add(habitId);
      }
    });
  }

  // Показ диалогового окна для создания привычки
  void _showAddHabitDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая привычка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Описание (необязательно)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                final newHabit = Habit(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                );
                await DatabaseHelper.instance.insertHabit(newHabit);
                Navigator.pop(context);
                _loadData(); // Перезагружаем список
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои Привычки'),
        subtitle: Text('Сегодня: $_today'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? const Center(child: Text('Список привычек пуст. Добавьте первую!'))
              : ListView.builder(
                  itemCount: _habits.length,
                  itemBuilder: (context) {
                    final habit = _habits[itemBuilder];
                    final isCompleted = _completedTodayIds.contains(habit.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          habit.title,
                          style: TextStyle(
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted ? Colors.grey : Colors.black,
                          ),
                        ),
                        subtitle: habit.description.isNotEmpty ? Text(habit.description) : null,
                        trailing: IconButton(
                          icon: Icon(
                            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isCompleted ? Colors.green : Colors.grey,
                          ),
                          onPressed: habit.id == null ? null : () => _onToggleHabit(habit.id!),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
