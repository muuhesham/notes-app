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
  Widget build(BuildContext context) {
    final filteredNotes =
        _searchQuery.isEmpty ? _notes : _hive.searchNotes(_searchQuery);
    // HomeScreen
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            label: Text(
              'Search for Notes by Title, Content, or Tag...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            border: InputBorder.none,
            icon: Icon(Icons.search),
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
                  color: const Color.fromARGB(255, 255, 35, 35),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            )
          : filteredNotes.isEmpty
              ? const Center(
                  child: Text(
                    'Welcome to Notes App!',
                    style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 30),
                  ),
                )
              : Column(
                children: [
                  Padding(padding: const EdgeInsets.all(12),
                  child: Text('Total Notes: ${filteredNotes.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 255, 255, 255)
                  )),
                  ),
                  Expanded(child:ListView.builder(
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) =>
                          _buildNoteCard(filteredNotes[index]),
                          
                    ), )
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
          _loadNotes();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Intialize the Notes
  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    setState(() {
      _notes = _hive.getNotes();
    });
  }

  // Note Card
  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.all(14),
      color: const Color.fromARGB(233, 197, 154, 0),
      child: ListTile(
        title: Text(note.title,
        style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold
        ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8,),
            note.isTodo
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: note.tasks.map((task) => Row(
                  children: [
                    Icon(
                      task.completed ? Icons.check_box : Icons.check_box_outline_blank,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(task.description, style: TextStyle(
                      fontWeight: FontWeight.bold
                    ),)),
                  ],
                )).toList(),
              )
            : Text(note.content, style: TextStyle(
              fontWeight: FontWeight.bold
            ),),
            SizedBox(height: 4,),
            Wrap(
              spacing: 4,
              children: note.tags.map((tag) => Chip(label: Text(tag))).toList(),
              
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Note',
              onPressed: () => _editNote(note),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Note',
              onPressed: () => _deleteNote(note.id),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share your Note',
              onPressed: () => Share.share('${note.title}\n\n${note.content}'),
            ),
          ],
        ),
      ),
    );
  }

  //Delete Note
  void _deleteNote(String id) async {
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
              await _hive.deleteNote(id);
              _loadNotes();
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  //Edit Note
  void _editNote(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNoteScreen(noteToEdit: note),
      ),
    );
    _loadNotes();
  }
}
