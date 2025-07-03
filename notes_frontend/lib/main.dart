import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A simple Note model.
class Note {
  String id;
  String title;
  String content;

  Note({
    required this.id,
    required this.title,
    required this.content,
  });

  // Convert Note to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
      };

  // Create Note from JSON
  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'],
      );
}

// Key for storing notes in SharedPreferences
const String notesPrefsKey = "notes_app_notes";

void main() {
  runApp(const NotesApp());
}

// PUBLIC_INTERFACE
class SettingsAboutPage extends StatelessWidget {
  /// Minimal Settings/About page for the app.
  const SettingsAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with any other required information/settings
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & About'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'NoteEase',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'A simple and minimalistic notes app.',
              style: TextStyle(fontSize: 16),
            ),
            Divider(height: 40),
            Text('Version: 1.0.0', style: TextStyle(fontSize: 14)),
            SizedBox(height: 6),
            Text('Created for demonstration purposes.', style: TextStyle(fontSize: 14)),
            SizedBox(height: 20),
            // Add more settings/about fields here
          ],
        ),
      ),
    );
  }
}

// PUBLIC_INTERFACE
class NotesApp extends StatelessWidget {
  /// Root of the Notes app with custom light, minimalistic theme.
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Color palette as per requirements
    const primaryColor = Color(0xFF1976D2);     // #1976D2
    const secondaryColor = Color(0xFF64B5F6);   // #64B5F6
    const accentColor = Color(0xFFFFB300);      // #FFB300

    return MaterialApp(
      title: 'Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          tertiary: accentColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0.5,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          elevation: 2,
        ),
        scaffoldBackgroundColor: Color(0xFFF9F9F9),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: primaryColor, width: 2),
            borderRadius: BorderRadius.circular(7),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: secondaryColor, width: 1),
            borderRadius: BorderRadius.circular(7),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        ),
        cardTheme: CardTheme(
          elevation: 1,
          color: Colors.white,
          shadowColor: const Color(0x29000000), // Use fixed alpha color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const NotesListPage(showDrawer: true), // Main notes screen with drawer
        '/about': (context) => const SettingsAboutPage(),
      },
      onGenerateRoute: (settings) {
        // For NoteDetailPage; settings.arguments can be a Note to edit, or null for new
        if (settings.name == '/note') {
          final noteArg = settings.arguments;
          return MaterialPageRoute(
            builder: (_) => NoteDetailPage(note: noteArg is Note ? noteArg : null),
          );
        }
        return null;
      },
    );
  }
}

/// Home page displaying a minimalistic list of notes, supporting add/delete and navigation drawer.
class NotesListPage extends StatefulWidget {
  final bool showDrawer;
  // showDrawer should be true for main screen so user can access about/settings, false if used as standalone

  // PUBLIC_INTERFACE
  const NotesListPage({super.key, this.showDrawer = false});

  @override
  State<NotesListPage> createState() => _NotesListPageState();
}

class _NotesListPageState extends State<NotesListPage> {
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  /// Loads notes from persistent storage.
  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString(notesPrefsKey);
    if (notesJson != null) {
      List<dynamic> decoded = jsonDecode(notesJson);
      _notes = decoded.map((n) => Note.fromJson(n)).toList();
    }
    setState(() => _isLoading = false);
  }

  /// Saves notes to persistent storage.
  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _notes.map((note) => note.toJson()).toList();
    prefs.setString(notesPrefsKey, jsonEncode(jsonList));
  }

  /// Handles adding or updating a note.
  Future<void> _upsertNote(Note note) async {
    setState(() {
      final idx = _notes.indexWhere((n) => n.id == note.id);
      if (idx >= 0) {
        _notes[idx] = note;
      } else {
        _notes.insert(0, note);
      }
    });
    await _saveNotes();
  }

  /// Handles deleting a note.
  Future<void> _deleteNote(Note note) async {
    setState(() {
      _notes.removeWhere((n) => n.id == note.id);
    });
    await _saveNotes();
  }

  /// Navigates to detail/edit page or to the note creation page (empty note).
  Future<void> _goToNoteDetails({Note? note}) async {
    final result = await Navigator.of(context).pushNamed<NoteActionResult>(
      '/note',
      arguments: note,
    );
    // result will be NoteActionResult
    if (result == null) return;
    final res = result;
    if (res.deleted) {
      await _deleteNote(res.note!);
    } else if (res.note != null) {
      await _upsertNote(res.note!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        centerTitle: true,
        actions: _notes.isEmpty
          ? []
          : [
              IconButton(
                tooltip: "Clear all notes",
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete all notes?"),
                      content: const Text("Are you sure you want to delete all your notes? This action cannot be undone."),
                      actions: [
                        TextButton(
                          child: const Text("Cancel"),
                          onPressed: () => Navigator.pop(context, false),
                        ),
                        TextButton(
                          child: const Text("Delete"),
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    ),
                  );
                  if (confirmed ?? false) {
                    setState(() => _notes.clear());
                    await _saveNotes();
                  }
                }
              )
            ],
      ),
      drawer: widget.showDrawer ? Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary
              ),
              child: const Text(
                'NoteEase',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('Notes List'),
              onTap: () {
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create Note'),
              onTap: () {
                Navigator.of(context).pushNamed('/note');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Settings/About'),
              onTap: () {
                Navigator.of(context).pushNamed('/about');
              },
            ),
          ],
        ),
      ) : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(
                  child: Text(
                    "No notes yet.\nTap the '+' button to create one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _notes.length,
                  itemBuilder: (_, idx) {
                    final note = _notes[idx];
                    // Leading border color accent
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Card(
                        child: ListTile(
                          onTap: () => _goToNoteDetails(note: note),
                          title: Text(
                            note.title.isEmpty ? '(No Title)' : note.title,
                            style: Theme.of(context).textTheme.titleLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: note.content.isEmpty
                              ? null
                              : Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    note.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                          trailing: IconButton(
                            tooltip: "Delete",
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Delete note?"),
                                  content: const Text("Are you sure you want to delete this note?"),
                                  actions: [
                                    TextButton(
                                      child: const Text("Cancel"),
                                      onPressed: () => Navigator.pop(context, false),
                                    ),
                                    TextButton(
                                      child: const Text("Delete"),
                                      onPressed: () => Navigator.pop(context, true),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed ?? false) {
                                await _deleteNote(note);
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Add Note",
        onPressed: () => _goToNoteDetails(),
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}

/// Result struct for note action navigation.
class NoteActionResult {
  final Note? note;
  final bool deleted;
  NoteActionResult({required this.note, this.deleted = false});
}

// PUBLIC_INTERFACE
class NoteDetailPage extends StatefulWidget {
  /// Page for creating and editing notes. Accepts an optional Note to edit.
  final Note? note;
  const NoteDetailPage({super.key, this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _dirty = false; // For unsaved changes warning

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? "");
    _contentController = TextEditingController(text: widget.note?.content ?? "");
    _titleController.addListener(() => setState(() => _dirty = true));
    _contentController.addListener(() => setState(() => _dirty = true));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Handles saving the note
  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title or content.")),
      );
      return;
    }
    final note = Note(
      id: widget.note?.id ?? UniqueKey().toString(),
      title: title,
      content: content,
    );
    Navigator.pop(context, NoteActionResult(note: note));
  }

  /// Handles delete
  Future<void> _deleteNote() async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete note?"),
        content: const Text("Are you sure you want to delete this note?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => navigator.pop(false),
          ),
          TextButton(
            child: const Text("Delete"),
            onPressed: () => navigator.pop(true),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      navigator.pop(NoteActionResult(note: widget.note, deleted: true));
    }
  }

  /// Handle back navigation with unsaved changes warning (using PopScope instead of deprecated WillPopScope)
  Future<bool> _onWillPop() async {
    if (!_dirty) return true;
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Discard changes?"),
        content: const Text(
            "You have unsaved changes. Discard them and leave?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => navigator.pop(false),
          ),
          TextButton(
            child: const Text("Discard"),
            onPressed: () => navigator.pop(true),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.note != null;
    final colorScheme = Theme.of(context).colorScheme;

    // Capture navigator before async gap to avoid using BuildContext after await
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        final navigator = Navigator.of(context);
        if (!didPop) return;
        final allowPop = await _onWillPop();
        if (!allowPop) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? "Edit Note" : "New Note"),
          elevation: 0.5,
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            if (isEdit)
              IconButton(
                tooltip: "Delete note",
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteNote,
              ),
            IconButton(
              tooltip: "Save note",
              icon: const Icon(Icons.check),
              onPressed: _saveNote,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: "Title",
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                maxLength: 50,
                autofocus: !isEdit,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: "Type your note here...",
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.check),
          label: const Text("Save"),
          backgroundColor: colorScheme.tertiary,
          foregroundColor: Colors.black,
          onPressed: _saveNote,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
