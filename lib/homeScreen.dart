import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:notepad/addNote.dart';
import 'package:notepad/hiveDatabase.dart';
import 'package:notepad/note_model.dart';
import 'package:share_plus/share_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HiveService _hive = HiveService();
  List<Note> _notes = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initializeNotificationsAndLoadNotes();
  }

  Future<void> _initializeNotificationsAndLoadNotes() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      isAllowed =
          await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    if (isAllowed) {
      print("Notification permissions are allowed.");
    } else {
      print("Notification permissions are NOT allowed.");
    }
    _loadNotesAndSchedule();
  }

  void _loadNotesAndSchedule() {
    setState(() {
      _notes = _hive.getNotes();
    });
    _scheduleAllNoteReminders();
  }

  void _scheduleAllNoteReminders() {
    final DateTime now = DateTime.now();
    int scheduledCount = 0;
    int cancelledCount = 0;

    for (var note in _notes) {
      if (note.id.isEmpty) {
        print("Skipping note with empty ID for scheduling.");
        continue;
      }
      final int notificationId = note.id.hashCode;

      final DateTime dueDateTime = note.date!;
      final DateTime notificationTime =
          dueDateTime.subtract(const Duration(minutes: 10));

      if (notificationTime.isAfter(now)) {
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: notificationId,
            channelKey: 'basic_channel',
            title: 'Reminder: ${note.title}',
            body:
                'Due at ${dueDateTime.hour.toString().padLeft(2, '0')}:${dueDateTime.minute.toString().padLeft(2, '0')}. Tap to see details.',
            notificationLayout: NotificationLayout.Default,
            category: NotificationCategory.Reminder,
            payload: {'noteId': note.id},
          ),
          schedule: NotificationCalendar.fromDate(
            date: notificationTime,
            allowWhileIdle: true,
          ),
        );
        scheduledCount++;
      } else {
        AwesomeNotifications().cancel(notificationId);
        cancelledCount++;
      }
    }
    print(
        "Notification scheduling complete. Scheduled: $scheduledCount, Cancelled/Cleaned: $cancelledCount");
  }

  void _deleteNote(String noteId) async {
    if (noteId.isEmpty) {
      print("Cannot delete note with empty ID.");
      return;
    }
    final int notificationId = noteId.hashCode;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await AwesomeNotifications().cancel(notificationId);
              print(
                  'Cancelled notification for deleted note (ID: $notificationId)');

              await _hive.deleteNote(noteId);
              Navigator.pop(context);
              _loadNotesAndSchedule();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNoteScreen(noteToEdit: note),
      ),
    );
    _loadNotesAndSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotes =
        _searchQuery.isEmpty ? _notes : _hive.searchNotes(_searchQuery);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: const InputDecoration(
            hintText: 'Search Notes by Title, Content, or Tag...',
            hintStyle: TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.white70,
            ),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.white),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        backgroundColor: const Color.fromARGB(255, 38, 37, 37),
      ),
      body: filteredNotes.isEmpty && _searchQuery.isNotEmpty
          ? const Center(
              child: Text(
                'No Notes Found!',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 35, 35),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            )
          : filteredNotes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.note_add_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notes yet!',
                        style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 24),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the "+" button to add a new note.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('Total Notes: ${filteredNotes.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredNotes.length,
                        itemBuilder: (context, index) =>
                            _buildNoteCard(filteredNotes[index]),
                      ),
                    )
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        tooltip: 'Add Note',
        shape: const CircleBorder(),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddNoteScreen(),
            ),
          );
          _loadNotesAndSchedule();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color.fromARGB(233, 197, 154, 0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black54),
                      tooltip: 'Edit Note',
                      onPressed: () => _editNote(note),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.black54),
                      tooltip: 'Delete Note',
                      onPressed: () => _deleteNote(note.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.black54),
                      tooltip: 'Share your Note',
                      onPressed: () => Share.share(
                          'Note: ${note.title}\n\n${note.content}\n\nTags: ${note.tags.join(", ")}'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (note.isTodo)
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: note.tasks
                      .map(
                        (task) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                task.completed
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                size: 20,
                                color: Colors.black87,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.description,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black.withOpacity(0.85),
                                    decoration: task.completed
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              )
            else
              Text(
                note.content.isEmpty ? "No content" : note.content,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: note.content.isEmpty
                      ? Colors.black54
                      : Colors.black.withOpacity(0.85),
                  fontSize: 15,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 10),
            if (note.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 0,
                children: note.tags
                    .map((tag) => Chip(
                          label:
                              Text(tag, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.black.withOpacity(0.1),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 0),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.alarm, color: Colors.black87, size: 18),
                const SizedBox(width: 6),
                Text(
                  getRemainingTime(note.date!),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String getRemainingTime(DateTime noteDate) {
    final now = DateTime.now();
    final difference = noteDate.difference(now);

    if (difference.isNegative) {
      return 'Overdue by ${difference.abs().inDays > 0 ? '${difference.abs().inDays}d' : difference.abs().inHours > 0 ? '${difference.abs().inHours}h' : '${difference.abs().inMinutes}m'}';
    } else if (difference.inDays > 0) {
      return 'Due in ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Due in ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Due in ${difference.inMinutes} min';
    } else {
      return 'Due very soon';
    }
  }
}
