// import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notepad/note_model.dart';


class HiveService {
  static final HiveService _instance = HiveService._internal();
  late Box<Note> _notesBox;
  factory HiveService() => _instance;
  HiveService._internal();
  
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    _notesBox = await Hive.openBox<Note>('notes');
  }

  // CRUD Operations in Hive
  List<Note> getNotes() => _notesBox.values.toList();
  Future<void> addNote(Note note) async => await _notesBox.put(note.id, note);
  Future<void> updateNote(Note note) async => await _notesBox.put(note.id, note);
  Future<void> deleteNote(String id) async => await _notesBox.delete(id);
  // Search Function
  List<Note> searchNotes(String query) {
    final lowerQuery = query.toLowerCase();

    return _notesBox.values.where((note) =>
      note.title.toLowerCase().contains(lowerQuery) ||
      note.content.toLowerCase().contains(lowerQuery) || note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
    ).toList();
  }
}