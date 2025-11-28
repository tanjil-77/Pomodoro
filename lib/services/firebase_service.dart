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

  // Health Integration Timer State operations
  static Future<void> saveWaterReminderState({
    required bool isRunning,
    required int remainingSeconds,
    required int totalSeconds,
    required DateTime startTime,
  }) async {
    await _firestore.collection('health_timers').doc('water_reminder').set({
      'isRunning': isRunning,
      'remainingSeconds': remainingSeconds,
      'totalSeconds': totalSeconds,
      'startTime': Timestamp.fromDate(startTime),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getWaterReminderState() async {
    try {
      final doc = await _firestore
          .collection('health_timers')
          .doc('water_reminder')
          .get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final startTime = (data['startTime'] as Timestamp).toDate();
      final lastUpdated = data['lastUpdated'] as Timestamp?;

      return {
        'isRunning': data['isRunning'] ?? false,
        'remainingSeconds': data['remainingSeconds'] ?? 0,
        'totalSeconds': data['totalSeconds'] ?? 0,
        'startTime': startTime,
        'lastUpdated': lastUpdated?.toDate(),
      };
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearWaterReminderState() async {
    await _firestore.collection('health_timers').doc('water_reminder').delete();
  }

  static Future<void> saveMedicineReminderState({
    required String medicineId,
    required bool isRunning,
    required int remainingSeconds,
    required int totalSeconds,
    required DateTime startTime,
  }) async {
    await _firestore
        .collection('health_timers')
        .doc('medicine_$medicineId')
        .set({
          'type': 'medicine',
          'medicineId': medicineId,
          'isRunning': isRunning,
          'remainingSeconds': remainingSeconds,
          'totalSeconds': totalSeconds,
          'startTime': Timestamp.fromDate(startTime),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
  }

  static Future<Map<String, dynamic>?> getMedicineReminderState(
    String medicineId,
  ) async {
    try {
      final doc = await _firestore
          .collection('health_timers')
          .doc('medicine_$medicineId')
          .get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final startTime = (data['startTime'] as Timestamp).toDate();
      final lastUpdated = data['lastUpdated'] as Timestamp?;

      return {
        'isRunning': data['isRunning'] ?? false,
        'remainingSeconds': data['remainingSeconds'] ?? 0,
        'totalSeconds': data['totalSeconds'] ?? 0,
        'startTime': startTime,
        'lastUpdated': lastUpdated?.toDate(),
      };
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearMedicineReminderState(String medicineId) async {
    await _firestore
        .collection('health_timers')
        .doc('medicine_$medicineId')
        .delete();
  }

  // Health history operations
  static Future<void> saveWaterIntakeHistory() async {
    await _firestore.collection('health_history').add({
      'type': 'water',
      'action': 'drink_water',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveMedicineIntakeHistory({
    required String medicineName,
    required String medicineId,
  }) async {
    await _firestore.collection('health_history').add({
      'type': 'medicine',
      'action': 'take_medicine',
      'medicineName': medicineName,
      'medicineId': medicineId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveExerciseHistory({
    required String exerciseName,
    required int durationSeconds,
  }) async {
    await _firestore.collection('health_history').add({
      'type': 'exercise',
      'action': 'complete_exercise',
      'exerciseName': exerciseName,
      'durationSeconds': durationSeconds,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveBMIHistory({
    required double bmi,
    required String bmiStage,
    required double height,
    required double weight,
  }) async {
    await _firestore.collection('health_history').add({
      'type': 'bmi',
      'action': 'calculate_bmi',
      'bmi': bmi,
      'bmiStage': bmiStage,
      'height': height,
      'weight': weight,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getHealthHistory({
    String? type,
    int limit = 100,
  }) async {
    Query query = _firestore
        .collection('health_history')
        .orderBy('timestamp', descending: true);

    if (type != null) {
      query = query.where('type', isEqualTo: type);
    }

    final snapshot = await query.limit(limit).get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;
      return {
        'id': doc.id,
        'type': data['type'],
        'action': data['action'],
        'medicineName': data['medicineName'],
        'medicineId': data['medicineId'],
        'exerciseName': data['exerciseName'],
        'durationSeconds': data['durationSeconds'],
        'bmi': data['bmi'],
        'bmiStage': data['bmiStage'],
        'height': data['height'],
        'weight': data['weight'],
        'timestamp': timestamp?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }

  static Future<void> clearHealthHistory() async {
    final snapshot = await _firestore.collection('health_history').get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
