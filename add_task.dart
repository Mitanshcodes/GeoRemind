import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _title = TextEditingController();
  final _location = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  void _submitManual() {
    final t = _title.text.trim();
    final l = _location.text.trim();
    if (t.isEmpty || l.isEmpty) return;
    // For now, fake geocoding: place near GT with slight offsets
    final id = const Uuid().v4();
    final lat = 33.774 + (id.hashCode % 100) / 10000.0;
    final lng = -84.3963 + (id.hashCode % 100) / 10000.0;

    final task = Task(id: id, title: t, locationText: l, lat: lat, lng: lng);
    context.read<TaskProvider>().addTask(task);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Task recorded'),
      backgroundColor: Colors.green.shade700,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Use AI (natural language) or manual input'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Frame for AI assist - not implemented
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('AI Assist'),
                    content: const Text('This would send the natural language text to an AI to parse and create a task.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
                    ],
                  ),
                );
              },
              child: const Text('Add via natural language (AI)'),
            ),
            const SizedBox(height: 20),
            const Text('Manual input'),
            const SizedBox(height: 8),
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Task title')),
            const SizedBox(height: 8),
            TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location (auto-fill)')),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _submitManual();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                  child: const Text('Enter'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    // Save any current manual input then go back
                    _submitManual();
                    Navigator.pop(context);
                  },
                  child: const Text('Done adding task'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
