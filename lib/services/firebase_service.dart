import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notepad operations
  static Future<void> saveNote(
    String noteId,
    String title,
    String content,
  ) async {
    await _firestore.collection('notes').doc(noteId).set({
      'title': title,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getNotes() async {
    final snapshot = await _firestore
        .collection('notes')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'content': data['content'] ?? '',
        'timestamp': data['timestamp'],
      };
    }).toList();
  }

  static Future<void> deleteNote(String noteId) async {
    await _firestore.collection('notes').doc(noteId).delete();
  }

  // History operations
  static Future<void> saveHistorySession(Map<String, dynamic> session) async {
    await _firestore.collection('history').add({
      'type': session['type'],
      'duration': session['duration'],
      'timestamp': session['timestamp'] is DateTime
          ? Timestamp.fromDate(session['timestamp'])
          : FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final snapshot = await _firestore
        .collection('history')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final timestamp = data['timestamp'] as Timestamp?;
      return {
        'type': data['type'],
        'duration': data['duration'],
        'timestamp': timestamp?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }

  static Future<void> clearHistory() async {
    final snapshot = await _firestore.collection('history').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Motivational speeches operations
  static Future<void> saveMotivationalSpeech(
    String speechId,
    String title,
    String url,
  ) async {
    await _firestore.collection('motivational_speeches').doc(speechId).set({
      'title': title,
      'url': url,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getMotivationalSpeeches() async {
    final snapshot = await _firestore
        .collection('motivational_speeches')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'url': data['url'] ?? '',
        'timestamp': data['timestamp'],
      };
    }).toList();
  }

  static Future<void> deleteMotivationalSpeech(String speechId) async {
    await _firestore.collection('motivational_speeches').doc(speechId).delete();
  }

  // Sync local data to Firebase (migration helper)
  static Future<void> syncHistoryToFirebase(
    List<Map<String, dynamic>> localHistory,
  ) async {
    for (var session in localHistory) {
      await saveHistorySession(session);
    }
  }
}
