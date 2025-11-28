import 'package:flutter/material.dart';
import 'services/firebase_service.dart';

class NotepadPage extends StatefulWidget {
  const NotepadPage({super.key});

  @override
  State<NotepadPage> createState() => _NotepadPageState();
}

class _NotepadPageState extends State<NotepadPage> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();
  final List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);
    try {
      final notes = await FirebaseService.getNotes();
      setState(() {
        _notes.clear();
        _notes.addAll(notes);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading notes: $e')));
      }
    }
  }

  Future<void> _addNoteFromController() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    try {
      final noteId = DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseService.saveNote(noteId, 'Note', text);

      final newNote = {
        'id': noteId,
        'title': 'Note',
        'content': text,
        'timestamp': DateTime.now(),
      };

      final index = _notes.length;
      _notes.insert(0, newNote);
      _listKey.currentState?.insertItem(
        0,
        duration: const Duration(milliseconds: 300),
      );
      _controller.clear();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Note saved to Firebase')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notepad")),
      body: Column(
        children: [
          // লেখার জায়গা
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Write your notes here...",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // Save বাটন
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _addNoteFromController,
              icon: const Icon(Icons.save),
              label: const Text("Save Note"),
            ),
          ),

          const SizedBox(height: 20),

          // Saved notes list দেখানো
          Expanded(
            child: _notes.isEmpty
                ? const Center(child: Text("No notes yet."))
                : AnimatedList(
                    key: _listKey,
                    initialItemCount: _notes.length,
                    itemBuilder: (context, index, animation) {
                      final item = _notes[index];
                      return SizeTransition(
                        sizeFactor: animation,
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.note),
                            title: Text(item),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editNoteDialog(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _confirmDelete(index),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int index) async {
    final should = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text(
          'This will remove the note from Firebase permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (should != true) return;

    try {
      final noteId = _notes[index]['id'];
      await FirebaseService.deleteNote(noteId);

      final removed = _notes.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.cloud),
              title: Text(removed['content'] ?? ''),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 300),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted from Firebase')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting note: $e')));
      }
    }
  }

  void _editNoteDialog(int index) {
    final editController = TextEditingController(
      text: _notes[index]['content'],
    );
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit note'),
        content: TextField(
          controller: editController,
          maxLines: 5,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newText = editController.text.trim();
              if (newText.isNotEmpty) {
                try {
                  final noteId = _notes[index]['id'];
                  await FirebaseService.saveNote(noteId, 'Note', newText);

                  setState(() {
                    _notes[index]['content'] = newText;
                  });

                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note updated in Firebase')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating note: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
