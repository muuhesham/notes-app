import 'package:flutter/material.dart';
import 'package:notepad/hiveDatabase.dart';
import 'package:notepad/note_model.dart';

class AddNoteScreen extends StatefulWidget {
  final Note? noteToEdit;

  const AddNoteScreen({super.key, this.noteToEdit});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;
  late final TextEditingController _taskController;
  DateTime? _selectedDateTime;
  late List<String> _tags;
  late bool _isTodo;
  late List<Task> _tasks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.noteToEdit != null ? 'Edit Note' : 'New Note',
          style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        backgroundColor: const Color.fromARGB(255, 12, 12, 12),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Add your Note Title',
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8))),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                'Is To-Do List',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: _isTodo,
              onChanged: (value) => setState(() => _isTodo = value),
            ),
            const SizedBox(height: 20),
            if (_isTodo) ...[
              _buildTaskList(),
              const SizedBox(height: 20),
            ] else ...[
              TextField(
                keyboardType: TextInputType.multiline,
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  hintText: 'Add your Note Content',
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
            ],
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                labelText: 'Add Tags (comma separated)',
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8))),
              ),
              onSubmitted: (value) {
                setState(() {
                  _tags.addAll(value
                      .split(',')
                      .map((t) => t.trim())
                      .where((t) => t.isNotEmpty));
                  _tagsController.clear();
                });
              },
            ),
            const SizedBox(height: 10),
            _buildTagChips(),
            const SizedBox(height: 30),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickDateTime,
                  child: Text("Pick Date & Time"),
                ),
                const SizedBox(width: 10),
                Text(
                  _selectedDateTime == null
                      ? 'No time set'
                      : '${_selectedDateTime!.toLocal()}'.split('.').first,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveNote,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  backgroundColor: Colors.blue),
              child: Text(
                widget.noteToEdit != null ? 'Update Note' : 'Save Note',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final note = widget.noteToEdit;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _tagsController = TextEditingController();
    _taskController = TextEditingController();
    _selectedDateTime = widget.noteToEdit?.date ?? DateTime.now();
    _tags = note?.tags.toList() ?? [];
    _isTodo = note?.isTodo ?? false;
    _tasks = note?.tasks
            .map(
                (t) => Task(description: t.description, completed: t.completed))
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _taskController.dispose();
    super.dispose();
  }

  void _saveNote() async {
    final hiveService = HiveService();

    // Valdiation
    if (_titleController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing Title'),
          content: const Text('Please enter a title for your note'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
      return;
    }

    // Routes for Update note or Add note
    final updatedNote = widget.noteToEdit?.copyWith(
          title: _titleController.text,
          content: _contentController.text,
          tags: _tags,
          isTodo: _isTodo,
          tasks: _tasks,
          date: _selectedDateTime,
        ) ??
        Note(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          content: _contentController.text,
          date: DateTime.now(),
          isTodo: _isTodo,
          tags: _tags,
          tasks: _tasks,
        );

    if (widget.noteToEdit != null) {
      await hiveService.updateNote(updatedNote);
    } else {
      await hiveService.addNote(updatedNote);
    }
    Navigator.pop(context);
  }

  Widget _buildTagChips() {
    return Wrap(
      spacing: 4,
      children: _tags
          .map((tag) => Chip(
                label: Text(tag),
                onDeleted: () => setState(() => _tags.remove(tag)),
              ))
          .toList(),
    );
  }

  Widget _buildTaskList() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return ListTile(
              leading: Checkbox(
                value: task.completed,
                onChanged: (value) => setState(() {
                  _tasks[index] = task.copyWith(completed: value ?? false);
                }),
              ),
              title: TextField(
                controller: TextEditingController(text: task.description),
                onChanged: (value) => setState(() {
                  _tasks[index] = task.copyWith(description: value);
                }),
                decoration: InputDecoration(
                  border: InputBorder.none,
                ),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => setState(() => _tasks.removeAt(index)),
              ),
            );
          },
        ),
        TextField(
          controller: _taskController,
          decoration: InputDecoration(
            labelText: 'Add new task',
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            suffixIcon: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                if (_taskController.text.isNotEmpty) {
                  setState(() {
                    _tasks.add(Task(
                      description: _taskController.text,
                      completed: false,
                    ));
                    _taskController.clear();
                  });
                }
              },
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                _tasks.add(Task(
                  description: value,
                  completed: false,
                ));
                _taskController.clear();
              });
            }
          },
        ),
      ],
    );
  }
}
