import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'widgets/top_banner.dart';
import 'services/firebase_service.dart';

class HealthIntegrationPage extends StatefulWidget {
  const HealthIntegrationPage({super.key});

  @override
  State<HealthIntegrationPage> createState() => _HealthIntegrationPageState();
}

class _HealthIntegrationPageState extends State<HealthIntegrationPage>
    with TickerProviderStateMixin {
  bool _waterReminderEnabled = true;
  double _waterReminderInterval = 60; // minutes
  final TextEditingController _intervalController = TextEditingController();
  AnimationController? _reminderController;
  int _reminderRemainingSeconds = 0;
  int _reminderTotalSeconds = 0;
  bool _reminderRunning = false;

  // Settings
  bool _alarmSound = true;
  bool _notificationSound = false;
  bool _vibrate = true;
  // Notification visibility is always on (system + in-app banner)

  // Notification and Audio
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setPlayerMode(PlayerMode.lowLatency);

  // Medicine Reminder State
  final GlobalKey<AnimatedListState> _medicineListKey =
      GlobalKey<AnimatedListState>();
  final List<MedicineReminder> _medicineReminders = [];
  AnimationController? _medicineController;
  int _medicineRemainingSeconds = 0;
  int _medicineTotalSeconds = 0;
  MedicineReminder? _activeMedicineReminder;

  // BMI Calculator State
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  double? _bmi;
  String _bmiStage = '';
  String _activityLevel =
      'sedentary'; // sedentary, light, moderate, active, very_active
  AnimationController? _bmiAnimationController;
  Animation<double>? _bmiScaleAnimation;

  final List<Map<String, dynamic>> _exercises = [
    {
      'id': 'neck_stretches',
      'title': 'Neck Stretches',
      'description': 'Tilt your head slowly from one side to the other.',
      'duration_seconds': 30,
      'reps': 2,
      'instructions': [
        'Sit or stand upright',
        'Tilt head to the right, hold 15s',
        'Tilt head to the left, hold 15s',
      ],
      'icon': Icons.self_improvement,
    },
    {
      'id': 'shoulder_rolls',
      'title': 'Shoulder Rolls',
      'description':
          'Roll shoulders backwards then forwards in a smooth motion.',
      'duration_seconds': 30,
      'reps': 3,
      'instructions': [
        'Stand or sit tall',
        'Lift shoulders up to ears',
        'Roll them back and down in a circle',
      ],
      'icon': Icons.rotate_right,
    },
    {
      'id': 'wrist_stretches',
      'title': 'Wrist Stretches',
      'description': 'Extend arm and flex wrist up and down slowly.',
      'duration_seconds': 20,
      'reps': 4,
      'instructions': [
        'Extend arm in front, palm down',
        'Gently bend wrist up and hold 5s',
        'Bend wrist down and hold 5s',
      ],
      'icon': Icons.pan_tool,
    },
    {
      'id': 'stand_and_stretch',
      'title': 'Stand & Stretch',
      'description': 'Reach for the sky and lengthen your body.',
      'duration_seconds': 20,
      'reps': 2,
      'instructions': [
        'Stand up slowly',
        'Reach arms overhead and interlace fingers',
        'Hold and breathe',
      ],
      'icon': Icons.accessibility_new,
    },
    {
      'id': 'eye_palming',
      'title': 'Eye Palming',
      'description': 'Warm palms and place over closed eyes to relax them.',
      'duration_seconds': 30,
      'reps': 1,
      'instructions': [
        'Rub palms together to warm',
        'Place gently over closed eyes',
        'Breathe slowly for 30 seconds',
      ],
      'icon': Icons.visibility,
    },
    {
      'id': 'deep_breathing',
      'title': 'Deep Breathing',
      'description': '4-4-4 breathing: inhale-hold-exhale each 4 seconds.',
      'duration_seconds': 16,
      'reps': 1,
      'instructions': ['Inhale 4s', 'Hold 4s', 'Exhale 4s'],
      'icon': Icons.air,
    },
    {
      'id': 'seated_leg_raises',
      'title': 'Seated Leg Raises',
      'description':
          'While seated, straighten one leg and hold to engage quads.',
      'duration_seconds': 20,
      'reps': 6,
      'instructions': [
        'Sit upright at edge of chair',
        'Straighten right leg and hold 3s',
        'Lower slowly and repeat for left leg',
      ],
      'icon': Icons.event_seat,
    },
    {
      'id': 'seated_march',
      'title': 'Seated March',
      'description': 'Lift knees alternately as if marching while seated.',
      'duration_seconds': 30,
      'reps': 1,
      'instructions': [
        'Sit tall and engage core',
        'Lift right knee, then left, in steady rhythm',
        'Continue for the duration',
      ],
      'icon': Icons.directions_run,
    },
    {
      'id': 'calf_raises',
      'title': 'Calf Raises',
      'description':
          'Raise up onto toes and lower back down to strengthen calves.',
      'duration_seconds': 20,
      'reps': 12,
      'instructions': [
        'Stand behind chair and hold the back for support',
        'Raise onto toes, hold 1-2s, lower back down',
      ],
      'icon': Icons.accessibility,
    },
    {
      'id': 'torso_twist',
      'title': 'Seated Torso Twist',
      'description':
          'Gently twist torso side to side to relieve lower back tension.',
      'duration_seconds': 30,
      'reps': 2,
      'instructions': [
        'Sit with feet flat',
        'Place hands on opposite knees',
        'Twist gently to each side and hold briefly',
      ],
      'icon': Icons.rotate_left,
    },
    {
      'id': 'hamstring_stretch',
      'title': 'Seated Hamstring Stretch',
      'description':
          'Extend one leg and reach toward your toes to stretch hamstrings.',
      'duration_seconds': 30,
      'reps': 2,
      'instructions': [
        'Sit on chair edge, extend one leg',
        'Keep back straight and hinge at hips to reach',
        'Hold then switch legs',
      ],
      'icon': Icons.accessibility_new,
    },
    {
      'id': 'chair_squats',
      'title': 'Chair Squats',
      'description': 'Stand up and sit down slowly to engage glutes and quads.',
      'duration_seconds': 30,
      'reps': 8,
      'instructions': [
        'Stand in front of a chair with feet hip-width',
        'Lower down as if to sit, barely touch, and stand back up',
        'Keep chest up and knees behind toes',
      ],
      'icon': Icons.square_foot,
    },
    {
      'id': 'desk_pushups',
      'title': 'Desk Push-ups',
      'description':
          'Hands on desk, body straight; bend elbows to lower chest towards desk.',
      'duration_seconds': 20,
      'reps': 10,
      'instructions': [
        'Place hands on sturdy desk at shoulder width',
        'Step feet back so body is in a straight line',
        'Lower chest to desk and push back up',
      ],
      'icon': Icons.push_pin,
    },
    {
      'id': 'ankle_rolls',
      'title': 'Ankle Rolls',
      'description':
          'Rotate ankles clockwise and counter-clockwise to loosen joints.',
      'duration_seconds': 20,
      'reps': 2,
      'instructions': [
        'Lift one foot slightly off the floor',
        'Rotate ankle in circles 10 times each direction',
        'Switch foot and repeat',
      ],
      'icon': Icons.loop,
    },
  ];

  @override
  void initState() {
    super.initState();
    _bmiAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bmiScaleAnimation = CurvedAnimation(
      parent: _bmiAnimationController!,
      curve: Curves.elasticOut,
    );
    _initNotifications();
    _loadSettings();
    _loadSoundSettings();
    _restoreTimerStates();
  }

  Future<void> _restoreTimerStates() async {
    // Restore water reminder state
    final waterState = await FirebaseService.getWaterReminderState();
    if (waterState != null && waterState['isRunning'] == true) {
      final startTime = waterState['startTime'] as DateTime;
      final totalSeconds = waterState['totalSeconds'] as int;
      final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;

      if (elapsedSeconds < totalSeconds) {
        setState(() {
          _waterReminderEnabled = true;
          _reminderRunning = true;
          _reminderTotalSeconds = totalSeconds;
          _reminderRemainingSeconds = totalSeconds - elapsedSeconds;
        });
        _startReminderFromState(totalSeconds - elapsedSeconds, totalSeconds);
      } else {
        await FirebaseService.clearWaterReminderState();
      }
    }

    // Restore medicine reminder states
    for (var reminder in _medicineReminders) {
      final medicineState = await FirebaseService.getMedicineReminderState(
        reminder.id,
      );
      if (medicineState != null && medicineState['isRunning'] == true) {
        final startTime = medicineState['startTime'] as DateTime;
        final totalSeconds = medicineState['totalSeconds'] as int;
        final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;

        if (elapsedSeconds < totalSeconds) {
          if (mounted) {
            setState(() {
              _activeMedicineReminder = reminder;
              _activeMedicineReminder!.isRunning = true;
              _medicineTotalSeconds = totalSeconds;
              _medicineRemainingSeconds = totalSeconds - elapsedSeconds;
            });
            _startMedicineReminderFromState(
              reminder,
              totalSeconds - elapsedSeconds,
              totalSeconds,
            );
          }
        } else {
          await FirebaseService.clearMedicineReminderState(reminder.id);
        }
      }
    }
  }

  void _startReminderFromState(int remainingSeconds, int totalSeconds) {
    if (_reminderController != null) {
      _reminderController!.dispose();
      _reminderController = null;
    }

    _reminderController = AnimationController(
      vsync: this,
      duration: Duration(seconds: remainingSeconds),
    );

    _reminderController!.addListener(() {
      if (!mounted) return;
      setState(() {
        final progress = _reminderController!.value;
        _reminderRemainingSeconds = (remainingSeconds * (1 - progress)).ceil();
      });

      // Save state periodically (every 10 seconds)
      if (_reminderRemainingSeconds % 10 == 0) {
        FirebaseService.saveWaterReminderState(
          isRunning: true,
          remainingSeconds: _reminderRemainingSeconds,
          totalSeconds: totalSeconds,
          startTime: DateTime.now().subtract(
            Duration(seconds: totalSeconds - _reminderRemainingSeconds),
          ),
        );
      }
    });

    _reminderController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onWaterReminderComplete();
        FirebaseService.clearWaterReminderState();
        if (_waterReminderEnabled && _reminderRunning) {
          _reminderController!.forward(from: 0);
          _startReminder(); // Restart with full duration
        }
      }
    });

    _reminderController!.forward(from: 0);
  }

  void _startMedicineReminderFromState(
    MedicineReminder reminder,
    int remainingSeconds,
    int totalSeconds,
  ) {
    if (_medicineController != null) {
      _medicineController!.dispose();
      _medicineController = null;
    }

    _medicineController = AnimationController(
      vsync: this,
      duration: Duration(seconds: remainingSeconds),
    );

    _medicineController!.addListener(() {
      if (!mounted) return;
      setState(() {
        final progress = _medicineController!.value;
        _medicineRemainingSeconds = (remainingSeconds * (1 - progress)).ceil();
      });

      // Save state periodically (every 10 seconds)
      if (_medicineRemainingSeconds % 10 == 0) {
        FirebaseService.saveMedicineReminderState(
          medicineId: reminder.id,
          isRunning: true,
          remainingSeconds: _medicineRemainingSeconds,
          totalSeconds: totalSeconds,
          startTime: DateTime.now().subtract(
            Duration(seconds: totalSeconds - _medicineRemainingSeconds),
          ),
        );
      }
    });

    _medicineController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Always save history when timer completes
        _onMedicineReminderComplete(reminder);

        if (reminder.isCourseCompleted) {
          _stopMedicineReminder(reminder);
          FirebaseService.clearMedicineReminderState(reminder.id);
          return;
        }

        if (_activeMedicineReminder != null &&
            _activeMedicineReminder!.isRunning &&
            !reminder.isCourseCompleted) {
          _medicineController!.forward(from: 0);
          _startMedicineReminder(reminder); // Restart with full duration
        }
      }
    });

    _medicineController!.forward(from: 0);
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Request notification permission for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _loadSoundSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _alarmSound = prefs.getBool('alarm_sound') ?? true;
        _notificationSound = prefs.getBool('notification_sound') ?? false;
        _vibrate = prefs.getBool('vibrate') ?? true;
        // Previously controlled by settings; now always on for reminders
      });
    } catch (e) {
      // Use defaults
    }
  }

  Future<void> _playNotificationSound() async {
    if (!_alarmSound && !_notificationSound) return;

    try {
      // Vibrate using HapticFeedback (guaranteed to work)
      if (_vibrate) {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        HapticFeedback.heavyImpact();
      }

      // Play system click sound instantly (guaranteed to work)
      await SystemSound.play(SystemSoundType.click);

      // Also try to play a longer beep in background
      Future.delayed(Duration.zero, () async {
        try {
          final player = AudioPlayer();
          await player.play(
            UrlSource(
              'https://actions.google.com/sounds/v1/alarms/beep_short.ogg',
            ),
          );
        } catch (e) {
          debugPrint('Background sound error: $e');
        }
      });

      debugPrint('System sound + haptic vibration played');
    } catch (e) {
      debugPrint('Sound play error: $e');
    }
  }

  Future<void> _triggerVibration() async {
    if (!_vibrate) return;

    try {
      final hasVibrator = await Vibration.hasVibrator();
      debugPrint('Device has vibrator: $hasVibrator');

      if (hasVibrator == true) {
        // Very strong vibration pattern - 5 long pulses
        await Vibration.vibrate(
          pattern: [0, 1500, 300, 1500, 300, 1500, 300, 1500, 300, 1500],
          intensities: [0, 255, 0, 255, 0, 255, 0, 255, 0, 255],
        );
        debugPrint('Vibration triggered successfully');
      } else {
        debugPrint('Device does not support vibration');
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
      // Fallback to simple vibration
      try {
        await Vibration.vibrate(duration: 2000);
        debugPrint('Fallback vibration triggered');
      } catch (e2) {
        debugPrint('Simple vibration also failed: $e2');
      }
    }
  }

  Future<void> _showHealthNotification(String title, String body) async {
    // Always show notification as requested

    final androidDetails = AndroidNotificationDetails(
      'health_reminders_v3',
      'Health Reminders',
      channelDescription: 'Water and medicine reminders',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: _vibrate,
      vibrationPattern: _vibrate
          ? Int64List.fromList([0, 1000, 400, 1000, 400, 1000])
          : null,
      playSound: _alarmSound || _notificationSound,
      ticker: 'Health Reminder Alert',
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
      enableLights: true,
      ledColor: const Color(0xFF6EA98D),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: false, // Don't show full screen
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public, // Show on lock screen
      channelShowBadge: true,
      autoCancel: true,
      ongoing: false,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: _alarmSound || _notificationSound,
      presentBadge: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Use unique ID based on current timestamp
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _notificationsPlugin.show(
        notificationId,
        title,
        body,
        notificationDetails,
      );
      debugPrint('✅ Health notification shown: $title');
    } catch (e) {
      debugPrint('❌ Health notification error: $e');
    }
  }

  Future<void> _onWaterReminderComplete() async {
    debugPrint('⏰ Water reminder completed!');

    // Save to history
    await FirebaseService.saveWaterIntakeHistory();

    // Show notification first (upore status bar e)
    await _showHealthNotification(
      '💧 Water Reminder',
      'Now time to drink water',
    );

    // In-app animated banner
    if (mounted) {
      TopBannerNotifier.show(
        context,
        title: 'Water Reminder',
        message: 'Now time to drink water',
        color: const Color(0xFF4FC3F7),
        icon: Icons.water_drop,
      );
    }

    // Then trigger vibration
    await _triggerVibration();

    // Finally play sound
    await _playNotificationSound();
  }

  Future<void> _onMedicineReminderComplete(MedicineReminder reminder) async {
    debugPrint('⏰ Medicine reminder completed: ${reminder.medicineName}');

    // Save to history with medicine ID
    await FirebaseService.saveMedicineIntakeHistory(
      medicineName: reminder.medicineName,
      medicineId: reminder.id,
    );

    // Show notification first (upore status bar e)
    await _showHealthNotification(
      '💊 Medicine Reminder',
      'Now time to eat medicine',
    );

    // In-app animated banner
    if (mounted) {
      TopBannerNotifier.show(
        context,
        title: 'Medicine Reminder',
        message: 'Now time to eat medicine',
        color: const Color(0xFFBA68C8),
        icon: Icons.medication,
      );
    }

    // Then trigger vibration
    await _triggerVibration();

    // Finally play sound
    await _playNotificationSound();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterReminderEnabled = prefs.getBool('health_water_enabled') ?? true;
      _waterReminderInterval = prefs.getDouble('health_water_interval') ?? 60;

      // Load BMI data
      final height = prefs.getDouble('bmi_height');
      final weight = prefs.getDouble('bmi_weight');
      if (height != null) _heightController.text = height.toString();
      if (weight != null) _weightController.text = weight.toString();
      _bmi = prefs.getDouble('bmi_value');
      _bmiStage = prefs.getString('bmi_stage') ?? '';
      _activityLevel = prefs.getString('bmi_activity_level') ?? 'sedentary';
    });
    _loadMedicineReminders();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('health_water_enabled', _waterReminderEnabled);
    await prefs.setDouble('health_water_interval', _waterReminderInterval);

    // Save BMI data
    if (_heightController.text.isNotEmpty) {
      await prefs.setDouble('bmi_height', double.parse(_heightController.text));
    }
    if (_weightController.text.isNotEmpty) {
      await prefs.setDouble('bmi_weight', double.parse(_weightController.text));
    }
    if (_bmi != null) {
      await prefs.setDouble('bmi_value', _bmi!);
      await prefs.setString('bmi_stage', _bmiStage);
    }
    await prefs.setString('bmi_activity_level', _activityLevel);

    await _saveMedicineReminders();
  }

  // --- Medicine Persistence ---
  Future<void> _saveMedicineReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> remindersJson = _medicineReminders
        .map((r) => json.encode(r.toJson()))
        .toList();
    await prefs.setStringList('medicine_reminders', remindersJson);
  }

  Future<void> _loadMedicineReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getStringList('medicine_reminders');
    if (remindersJson != null) {
      setState(() {
        _medicineReminders.clear();
        final loadedReminders = remindersJson
            .map(
              (jsonString) =>
                  MedicineReminder.fromJson(json.decode(jsonString)),
            )
            .toList();
        for (var i = 0; i < loadedReminders.length; i++) {
          _medicineReminders.add(loadedReminders[i]);
          _medicineListKey.currentState?.insertItem(i, duration: Duration.zero);
        }
      });
    }
  }

  @override
  void dispose() {
    _reminderController?.dispose();
    _reminderController = null;
    _medicineController?.dispose();
    _medicineController = null;
    _bmiAnimationController?.dispose();
    _bmiAnimationController = null;
    _heightController.dispose();
    _weightController.dispose();
    _intervalController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // BMI Calculation
  void _calculateBMI() {
    final heightInches = double.tryParse(_heightController.text);
    final weightKg = double.tryParse(_weightController.text);

    if (heightInches == null ||
        weightKg == null ||
        heightInches <= 0 ||
        weightKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid height and weight')),
      );
      return;
    }

    // Convert inches to meters (1 inch = 0.0254 meters)
    final heightM = heightInches * 0.0254;

    // Calculate BMI: weight(kg) / height(m)²
    final bmiValue = weightKg / (heightM * heightM);

    setState(() {
      _bmi = bmiValue;

      // Adjust BMI interpretation based on activity level
      double adjustedBMI = bmiValue;

      // Activity level adjustments for better health assessment
      switch (_activityLevel) {
        case 'very_active':
          adjustedBMI =
              bmiValue - 0.5; // Athletes may have higher BMI due to muscle
          break;
        case 'active':
          adjustedBMI = bmiValue - 0.3;
          break;
        case 'moderate':
          adjustedBMI = bmiValue - 0.1;
          break;
        case 'light':
          adjustedBMI = bmiValue;
          break;
        case 'sedentary':
        default:
          adjustedBMI =
              bmiValue +
              0.2; // Sedentary lifestyle may need stricter assessment
          break;
      }

      if (adjustedBMI < 18.5) {
        _bmiStage = 'Underweight';
      } else if (adjustedBMI < 25) {
        _bmiStage = 'Normal';
      } else if (adjustedBMI < 30) {
        _bmiStage = 'Overweight';
      } else {
        _bmiStage = 'Obese';
      }
    });

    _bmiAnimationController?.reset();
    _bmiAnimationController?.forward();
    _saveSettings();

    // Save BMI calculation to history
    FirebaseService.saveBMIHistory(
      bmi: bmiValue,
      bmiStage: _bmiStage,
      height: heightInches,
      weight: weightKg,
    );
  }

  String _getActivityLevelLabel(String level) {
    switch (level) {
      case 'sedentary':
        return 'Sedentary (Little/No Exercise)';
      case 'light':
        return 'Light (1-2 days/week)';
      case 'moderate':
        return 'Moderate (3-5 days/week)';
      case 'active':
        return 'Active (6-7 days/week)';
      case 'very_active':
        return 'Very Active (Athlete)';
      default:
        return 'Sedentary';
    }
  }

  Color _getBMIColor() {
    if (_bmi == null) return Colors.grey;
    if (_bmi! < 18.5) return const Color(0xFF2196F3); // Bright blue
    if (_bmi! < 25) return const Color(0xFF4CAF50); // Bright green
    if (_bmi! < 30) return const Color(0xFFFF9800); // Bright orange
    return const Color(0xFFF44336); // Bright red
  }

  List<Map<String, dynamic>> _getFilteredExercises() {
    if (_bmi == null) {
      // Default exercises for general wellness
      return _exercises.take(6).toList();
    }

    if (_bmi! < 18.5) {
      // Underweight: Focus on strength building and muscle gain
      return [
        {
          'id': 'chair_squats',
          'title': 'Chair Squats',
          'description': 'Build leg strength and muscle mass.',
          'duration_seconds': 30,
          'reps': 10,
          'instructions': [
            'Stand in front of a chair with feet hip-width',
            'Lower down slowly, barely touch seat, stand back up',
            'Keep chest up and core engaged',
          ],
          'icon': Icons.square_foot,
        },
        {
          'id': 'desk_pushups',
          'title': 'Desk Push-ups',
          'description': 'Upper body strength and muscle building.',
          'duration_seconds': 20,
          'reps': 12,
          'instructions': [
            'Hands on sturdy desk at shoulder width',
            'Body in straight line, lower chest to desk',
            'Push back up with control',
          ],
          'icon': Icons.push_pin,
        },
        {
          'id': 'resistance_band_rows',
          'title': 'Resistance Band Rows',
          'description': 'Strengthen back muscles.',
          'duration_seconds': 30,
          'reps': 12,
          'instructions': [
            'Secure band at chest height',
            'Pull handles to sides, squeeze shoulder blades',
            'Return with control',
          ],
          'icon': Icons.fitness_center,
        },
        {
          'id': 'wall_sits',
          'title': 'Wall Sits',
          'description': 'Build leg endurance and strength.',
          'duration_seconds': 30,
          'reps': 3,
          'instructions': [
            'Back against wall, slide down to 90° knee bend',
            'Hold position, keep core tight',
            'Stand back up slowly',
          ],
          'icon': Icons.airline_seat_recline_normal,
        },
        {
          'id': 'bicep_curls',
          'title': 'Bicep Curls',
          'description': 'Build arm strength with light weights.',
          'duration_seconds': 30,
          'reps': 15,
          'instructions': [
            'Hold light weights or water bottles',
            'Curl up slowly, lower with control',
            'Keep elbows close to body',
          ],
          'icon': Icons.sports_martial_arts,
        },
        {
          'id': 'plank_hold',
          'title': 'Plank Hold',
          'description': 'Core strengthening exercise.',
          'duration_seconds': 20,
          'reps': 3,
          'instructions': [
            'Forearms on ground, body in straight line',
            'Hold position, engage core',
            'Breathe steadily',
          ],
          'icon': Icons.accessibility_new,
        },
      ];
    } else if (_bmi! < 25) {
      // Normal: Balanced exercises for maintenance and fitness
      return [
        {
          'id': 'jumping_jacks',
          'title': 'Jumping Jacks',
          'description': 'Full body cardio warmup.',
          'duration_seconds': 30,
          'reps': 1,
          'instructions': [
            'Start with feet together, arms at sides',
            'Jump feet apart while raising arms overhead',
            'Jump back to start position',
          ],
          'icon': Icons.directions_run,
        },
        {
          'id': 'burpees',
          'title': 'Burpees',
          'description': 'High-intensity full body exercise.',
          'duration_seconds': 30,
          'reps': 10,
          'instructions': [
            'Start standing, drop to plank',
            'Do a push-up, jump feet forward',
            'Jump up with arms overhead',
          ],
          'icon': Icons.fitness_center,
        },
        {
          'id': 'mountain_climbers',
          'title': 'Mountain Climbers',
          'description': 'Cardio and core strengthener.',
          'duration_seconds': 30,
          'reps': 1,
          'instructions': [
            'Start in plank position',
            'Alternate bringing knees to chest quickly',
            'Keep core tight, hips level',
          ],
          'icon': Icons.terrain,
        },
        {
          'id': 'lunges',
          'title': 'Forward Lunges',
          'description': 'Leg strength and balance.',
          'duration_seconds': 30,
          'reps': 12,
          'instructions': [
            'Step forward into lunge, knee at 90°',
            'Push back to standing',
            'Alternate legs',
          ],
          'icon': Icons.directions_walk,
        },
        {
          'id': 'plank_variations',
          'title': 'Plank Variations',
          'description': 'Core stability workout.',
          'duration_seconds': 40,
          'reps': 1,
          'instructions': [
            'Hold plank 15s, side plank left 10s',
            'Side plank right 10s',
            'Return to center plank 5s',
          ],
          'icon': Icons.accessibility,
        },
        {
          'id': 'high_knees',
          'title': 'High Knees',
          'description': 'Cardio and leg endurance.',
          'duration_seconds': 30,
          'reps': 1,
          'instructions': [
            'Run in place, lift knees high',
            'Pump arms, quick pace',
            'Keep core engaged',
          ],
          'icon': Icons.run_circle,
        },
      ];
    } else if (_bmi! < 30) {
      // Overweight: Low-impact cardio and fat-burning exercises
      return [
        {
          'id': 'brisk_walking',
          'title': 'Brisk Walking',
          'description': 'Low-impact cardio to burn calories.',
          'duration_seconds': 300,
          'reps': 1,
          'instructions': [
            'Walk at a steady, brisk pace',
            'Swing arms naturally',
            'Maintain good posture',
          ],
          'icon': Icons.directions_walk,
        },
        {
          'id': 'chair_squats',
          'title': 'Chair Squats',
          'description': 'Safe leg strengthening exercise.',
          'duration_seconds': 30,
          'reps': 12,
          'instructions': [
            'Use chair for support',
            'Lower slowly, stand back up',
            'Control the movement',
          ],
          'icon': Icons.event_seat,
        },
        {
          'id': 'wall_pushups',
          'title': 'Wall Push-ups',
          'description': 'Upper body strength, low impact.',
          'duration_seconds': 30,
          'reps': 15,
          'instructions': [
            'Hands on wall at shoulder height',
            'Lean in, push back out',
            'Keep body straight',
          ],
          'icon': Icons.push_pin,
        },
        {
          'id': 'seated_march',
          'title': 'Seated March',
          'description': 'Gentle cardio while seated.',
          'duration_seconds': 60,
          'reps': 1,
          'instructions': [
            'Sit tall, march knees up alternately',
            'Pump arms for added intensity',
            'Maintain steady rhythm',
          ],
          'icon': Icons.airline_seat_recline_normal,
        },
        {
          'id': 'step_ups',
          'title': 'Step-Ups',
          'description': 'Cardio and leg strength.',
          'duration_seconds': 30,
          'reps': 20,
          'instructions': [
            'Use low step or stair',
            'Step up with right, then left',
            'Step down with control',
          ],
          'icon': Icons.stairs,
        },
        {
          'id': 'arm_circles',
          'title': 'Arm Circles',
          'description': 'Shoulder mobility and light cardio.',
          'duration_seconds': 30,
          'reps': 1,
          'instructions': [
            'Extend arms to sides',
            'Make small circles, then larger',
            'Reverse direction halfway',
          ],
          'icon': Icons.rotate_right,
        },
      ];
    } else {
      // Obese: Very low-impact exercises, focus on gentle movement
      return [
        {
          'id': 'seated_stretches',
          'title': 'Seated Stretches',
          'description': 'Gentle full-body flexibility.',
          'duration_seconds': 60,
          'reps': 1,
          'instructions': [
            'Sit comfortably, reach arms overhead',
            'Gentle side stretches',
            'Breathe deeply throughout',
          ],
          'icon': Icons.self_improvement,
        },
        {
          'id': 'water_aerobics',
          'title': 'Water Aerobics',
          'description': 'Joint-friendly cardio exercise.',
          'duration_seconds': 300,
          'reps': 1,
          'instructions': [
            'Perform exercises in pool if available',
            'Water reduces joint stress',
            'Move at comfortable pace',
          ],
          'icon': Icons.pool,
        },
        {
          'id': 'chair_yoga',
          'title': 'Chair Yoga',
          'description': 'Gentle flexibility and relaxation.',
          'duration_seconds': 60,
          'reps': 1,
          'instructions': [
            'Seated twists and stretches',
            'Focus on breathing',
            'Move gently, never force',
          ],
          'icon': Icons.spa,
        },
        {
          'id': 'ankle_pumps',
          'title': 'Ankle Pumps',
          'description': 'Improve circulation, gentle movement.',
          'duration_seconds': 30,
          'reps': 1,
          'instructions': [
            'Sit with feet flat',
            'Point toes up and down',
            'Rotate ankles gently',
          ],
          'icon': Icons.loop,
        },
        {
          'id': 'deep_breathing',
          'title': 'Deep Breathing Exercise',
          'description': 'Relaxation and oxygenation.',
          'duration_seconds': 60,
          'reps': 1,
          'instructions': [
            'Sit comfortably, close eyes',
            'Breathe in deeply for 4 counts',
            'Hold 4, exhale 4, repeat',
          ],
          'icon': Icons.air,
        },
        {
          'id': 'gentle_walking',
          'title': 'Gentle Walking',
          'description': 'Start with short, easy walks.',
          'duration_seconds': 180,
          'reps': 1,
          'instructions': [
            'Walk at comfortable pace',
            'Start with 3 minutes, build gradually',
            'Focus on consistency over intensity',
          ],
          'icon': Icons.directions_walk,
        },
      ];
    }
  }

  void _startReminder() {
    if (_reminderController != null) {
      _reminderController!.dispose();
      _reminderController = null;
    }
    _reminderTotalSeconds = (_waterReminderInterval * 60).toInt();
    if (_reminderTotalSeconds <= 0) return;
    _reminderController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _reminderTotalSeconds),
    );
    _reminderRunning = true;

    // Save initial state to Firebase
    final startTime = DateTime.now();
    FirebaseService.saveWaterReminderState(
      isRunning: true,
      remainingSeconds: _reminderTotalSeconds,
      totalSeconds: _reminderTotalSeconds,
      startTime: startTime,
    );

    _reminderController!.addListener(() {
      if (!mounted) return;
      setState(() {
        final progress = _reminderController!.value;
        _reminderRemainingSeconds = (_reminderTotalSeconds * (1 - progress))
            .ceil();
      });

      // Save state periodically (every 10 seconds)
      if (_reminderRemainingSeconds % 10 == 0) {
        FirebaseService.saveWaterReminderState(
          isRunning: true,
          remainingSeconds: _reminderRemainingSeconds,
          totalSeconds: _reminderTotalSeconds,
          startTime: startTime,
        );
      }
    });
    _reminderController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Time to drink water!')),
        );
        // Trigger notification, sound, and vibration
        _onWaterReminderComplete();
        FirebaseService.clearWaterReminderState();
        if (_waterReminderEnabled && _reminderRunning) {
          _reminderController!.forward(from: 0);
          _startReminder(); // Restart properly
        }
      }
    });
    _reminderController!.forward(from: 0);
  }

  void _stopReminder() {
    if (_reminderController != null) {
      _reminderController!.stop();
      _reminderController!.dispose();
      _reminderController = null;
    }
    _reminderRunning = false;
    FirebaseService.clearWaterReminderState();
    setState(() {});
  }

  // --- Medicine Reminder Logic ---

  void _startMedicineReminder(MedicineReminder reminder) {
    if (_medicineController != null) {
      _medicineController!.dispose();
      _medicineController = null;
    }
    _medicineTotalSeconds = (reminder.intervalHours * 3600).toInt();
    if (_medicineTotalSeconds <= 0) return;

    _medicineController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _medicineTotalSeconds),
    );

    setState(() {
      // Set start date only if it's null and course has duration
      if (reminder.courseStartDate == null && reminder.totalCourseDays > 0) {
        reminder.courseStartDate = DateTime.now();
        _saveMedicineReminders(); // Save the start date
      }
      _activeMedicineReminder = reminder;
      _activeMedicineReminder!.isRunning = true;
    });

    // Save initial state to Firebase
    final medicineStartTime = DateTime.now();
    FirebaseService.saveMedicineReminderState(
      medicineId: reminder.id,
      isRunning: true,
      remainingSeconds: _medicineTotalSeconds,
      totalSeconds: _medicineTotalSeconds,
      startTime: medicineStartTime,
    );

    _medicineController!.addListener(() {
      if (!mounted) return;
      setState(() {
        final progress = _medicineController!.value;
        _medicineRemainingSeconds = (_medicineTotalSeconds * (1 - progress))
            .ceil();
      });

      // Save state periodically (every 10 seconds)
      if (_medicineRemainingSeconds % 10 == 0) {
        FirebaseService.saveMedicineReminderState(
          medicineId: reminder.id,
          isRunning: true,
          remainingSeconds: _medicineRemainingSeconds,
          totalSeconds: _medicineTotalSeconds,
          startTime: medicineStartTime,
        );
      }
    });

    _medicineController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Check if course is completed
        if (reminder.isCourseCompleted) {
          _stopMedicineReminder(reminder);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ ${reminder.medicineName} course completed! Well done! 🎉',
                ),
                backgroundColor: Colors.teal,
                duration: const Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Time to take your ${reminder.medicineName}! (${reminder.getTimingDetails()})',
            ),
          ),
        );
        // Trigger notification, sound, and vibration
        _onMedicineReminderComplete(reminder);
        FirebaseService.clearMedicineReminderState(reminder.id);
        if (_activeMedicineReminder != null &&
            _activeMedicineReminder!.isRunning &&
            !reminder.isCourseCompleted) {
          _medicineController!.forward(
            from: 0,
          ); // Restart timer if not completed
          _startMedicineReminder(reminder); // Restart properly
        }
      }
    });
    _medicineController!.forward(from: 0);
  }

  void _stopMedicineReminder(MedicineReminder reminder) {
    if (_activeMedicineReminder?.id == reminder.id) {
      _medicineController?.stop();
      _medicineController?.dispose();
      _medicineController = null;
      FirebaseService.clearMedicineReminderState(reminder.id);
      setState(() {
        _activeMedicineReminder = null;
        _medicineRemainingSeconds = 0;
      });
    }
    setState(() {
      reminder.isRunning = false;
    });
  }

  void _addMedicineReminder(MedicineReminder reminder) {
    // No need to call setState, AnimatedList handles it
    final newIndex = _medicineReminders.length;
    _medicineReminders.add(reminder);
    _medicineListKey.currentState?.insertItem(newIndex);
    _saveMedicineReminders(); // Save after adding
  }

  void _removeMedicineReminder(MedicineReminder reminder, int index) {
    final removedItem = _medicineReminders.removeAt(index);
    _medicineListKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _buildMedicineItem(context, removedItem, animation, index),
      duration: const Duration(milliseconds: 400),
    );
    if (_activeMedicineReminder?.id == removedItem.id) {
      _stopMedicineReminder(removedItem);
    }
    _saveMedicineReminders(); // Save after removing
  }

  @override
  Widget build(BuildContext context) {
    final themeBg = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Integration'),
        backgroundColor: themeBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _waterCard(context),
            const SizedBox(height: 20),
            _medicineCard(context),
            const SizedBox(height: 20),
            _bmiCard(context),
            const SizedBox(height: 20),
            _exerciseHeader(),
            const SizedBox(height: 12),
            ..._getFilteredExercises().map((e) => _exerciseTile(e)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _waterCard(BuildContext context) {
    final themeBg = Theme.of(context).scaffoldBackgroundColor;
    // water reminder gradient blends scaffold color with a soft teal
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeBg, // blend with scaffold
            Color.fromRGBO(0, 150, 136, 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Water Reminder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Highlighted switch container so it stands out on any background
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color.fromRGBO(2, 136, 209, 0.14)
                    : const Color.fromRGBO(2, 136, 209, 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
                title: Text(
                  'Enable water reminders',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                value: _waterReminderEnabled,
                onChanged: (v) async {
                  setState(() => _waterReminderEnabled = v);
                  final messenger = ScaffoldMessenger.of(context);
                  await _saveSettings();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        v
                            ? 'Water reminders enabled'
                            : 'Water reminders disabled',
                      ),
                    ),
                  );
                },
                activeColor: Colors.blueAccent,
                tileColor: Colors.transparent,
                secondary: _reminderRunning
                    ? const Icon(Icons.water_drop, color: Colors.blueAccent)
                    : const Icon(Icons.water_damage, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _intervalController
                      ..text = _waterReminderInterval.toInt().toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minutes between reminders',
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final parsed = int.tryParse(v);
                      if (parsed != null && parsed > 0) {
                        setState(
                          () => _waterReminderInterval = parsed.toDouble(),
                        );
                        _saveSettings();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _waterReminderEnabled
                      ? () {
                          if (_reminderRunning) {
                            _stopReminder();
                          } else {
                            _startReminder();
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _reminderRunning
                        ? Colors.redAccent
                        : Colors.blueAccent,
                  ),
                  child: Text(_reminderRunning ? 'Stop' : 'Start'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Animated progress bar for in-session reminder
            if (_reminderRunning)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _reminderTotalSeconds > 0
                        ? (_reminderTotalSeconds - _reminderRemainingSeconds) /
                              _reminderTotalSeconds
                        : 0,
                    color: Colors.blueAccent,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.white12
                        : Colors.black12,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Next reminder in ${(_reminderRemainingSeconds / 60).ceil()} min ${_reminderRemainingSeconds % 60} sec',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await _saveSettings();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Settings saved')),
                    );
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Medicine Reminder Widgets ---

  Widget _medicineCard(BuildContext context) {
    final theme = Theme.of(context);
    final themeBg = theme.scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeBg,
            const Color.fromRGBO(126, 87, 194, 0.15), // Deep purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Medicine Reminders',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle,
                    color: Colors.deepPurpleAccent,
                    size: 30,
                  ),
                  onPressed: () => _showAddEditMedicineDialog(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_medicineReminders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.medication_liquid,
                        size: 40,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No reminders yet.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      Text(
                        'Tap + to add your first one!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            AnimatedList(
              key: _medicineListKey,
              initialItemCount: _medicineReminders.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index, animation) {
                final reminder = _medicineReminders[index];
                return _buildMedicineItem(context, reminder, animation, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _bmiCard(BuildContext context) {
    final theme = Theme.of(context);
    final themeBg = theme.scaffoldBackgroundColor;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.scale(
        scale: 0.95 + (0.05 * value),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeBg,
              theme.brightness == Brightness.dark
                  ? const Color.fromRGBO(
                      103,
                      58,
                      183,
                      0.15,
                    ) // Deep purple for dark
                  : const Color.fromRGBO(
                      103,
                      58,
                      183,
                      0.12,
                    ), // Deep purple for light
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.monitor_weight,
                      color: Colors.deepPurple[400],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'BMI Calculator',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HEIGHT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.deepPurple[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'inches',
                            labelStyle: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white60
                                  : Colors.black45,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.height,
                              color: Colors.deepPurple[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.deepPurple[200]!,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.deepPurple.withValues(alpha: 0.5)
                                    : Colors.deepPurple.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.deepPurple[400]!,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: theme.brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.deepPurple.withValues(alpha: 0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WEIGHT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: Colors.deepPurple[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            labelText: 'kg',
                            labelStyle: TextStyle(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white60
                                  : Colors.black45,
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.fitness_center,
                              color: Colors.deepPurple[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.deepPurple[200]!,
                                width: 1.5,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.deepPurple.withValues(alpha: 0.5)
                                    : Colors.deepPurple.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.deepPurple[400]!,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: theme.brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.deepPurple.withValues(alpha: 0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Activity Level Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVITY LEVEL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.deepPurple[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.deepPurple.withValues(alpha: 0.5)
                            : Colors.deepPurple.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.deepPurple.withValues(alpha: 0.05),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _activityLevel,
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.deepPurple[400],
                        ),
                        style: TextStyle(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        dropdownColor: theme.brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.white,
                        items: [
                          DropdownMenuItem(
                            value: 'sedentary',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_seat,
                                  size: 18,
                                  color: Colors.deepPurple[400],
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Sedentary (Little/No Exercise)'),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'light',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_walk,
                                  size: 18,
                                  color: Colors.deepPurple[400],
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Light (1-2 days/week)'),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'moderate',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_run,
                                  size: 18,
                                  color: Colors.deepPurple[400],
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Moderate (3-5 days/week)'),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 18,
                                  color: Colors.deepPurple[400],
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Active (6-7 days/week)'),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'very_active',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sports,
                                  size: 18,
                                  color: Colors.deepPurple[400],
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text('Very Active (Athlete)'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _activityLevel = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _calculateBMI,
                  icon: const Icon(Icons.calculate, size: 22),
                  label: const Text(
                    'Calculate BMI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    elevation: 4,
                    shadowColor: Colors.deepPurple.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_bmi != null) ...[
                const SizedBox(height: 20),
                ScaleTransition(
                  scale: _bmiScaleAnimation!,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getBMIColor().withValues(alpha: 0.1),
                          _getBMIColor().withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getBMIColor(), width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your BMI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _bmi!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _getBMIColor(),
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: _getBMIColor().withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getBMIColor(),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: _getBMIColor().withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _bmiStage,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 14,
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white60
                                    : Colors.black45,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Based on ${_getActivityLevelLabel(_activityLevel).split('(')[0].trim()} activity',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.brightness == Brightness.dark
                                        ? Colors.white60
                                        : Colors.black45,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getBMIDescription(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getBMIDescription() {
    if (_bmi == null) return '';
    if (_bmi! < 18.5) {
      return 'Exercise suggestions focus on strength building and muscle gain.';
    } else if (_bmi! < 25) {
      return 'Exercise suggestions include balanced fitness and maintenance.';
    } else if (_bmi! < 30) {
      return 'Exercise suggestions focus on low-impact cardio and fat burning.';
    } else {
      return 'Exercise suggestions are gentle movements, perfect for getting started.';
    }
  }

  Widget _buildMedicineItem(
    BuildContext context,
    MedicineReminder reminder,
    Animation<double> animation,
    int index,
  ) {
    final bool isActive = _activeMedicineReminder?.id == reminder.id;
    final theme = Theme.of(context);
    final bool isCompleted = reminder.isCourseCompleted;

    return ScaleTransition(
      scale: animation,
      child: Opacity(
        opacity: isCompleted ? 0.5 : 1.0,
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            child: Column(
              children: [
                ListTile(
                  leading: isCompleted
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.teal,
                          size: 32,
                        )
                      : const Icon(
                          Icons.medication,
                          color: Colors.deepPurpleAccent,
                          size: 32,
                        ),
                  title: Text(
                    reminder.medicineName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  subtitle: Text(
                    reminder.getTimingDetails(),
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color?.withAlpha(204),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note,
                          size: 24,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () =>
                            _showAddEditMedicineDialog(reminder: reminder),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_sweep,
                          color: Colors.redAccent,
                          size: 24,
                        ),
                        onPressed: () =>
                            _removeMedicineReminder(reminder, index),
                      ),
                    ],
                  ),
                ),
                if (reminder.reminderType == ReminderType.interval)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(
                              reminder.isRunning
                                  ? Icons.stop_circle_outlined
                                  : Icons.play_circle_outline,
                            ),
                            onPressed: isCompleted
                                ? null
                                : () {
                                    if (reminder.isRunning) {
                                      _stopMedicineReminder(reminder);
                                    } else {
                                      _startMedicineReminder(reminder);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: reminder.isRunning
                                  ? Colors.redAccent
                                  : Colors.deepPurpleAccent,
                              disabledBackgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            label: Text(
                              isCompleted
                                  ? 'Course Completed'
                                  : (reminder.isRunning
                                        ? 'Stop Timer'
                                        : 'Start Timer'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _medicineTotalSeconds > 0
                              ? (_medicineTotalSeconds -
                                        _medicineRemainingSeconds) /
                                    _medicineTotalSeconds
                              : 0,
                          color: Colors.deepPurpleAccent,
                          backgroundColor: theme.brightness == Brightness.dark
                              ? Colors.white12
                              : Colors.black12,
                          minHeight: 6,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Next dose in ${(_medicineRemainingSeconds / 3600).floor()}h ${((_medicineRemainingSeconds % 3600) / 60).floor()}m ${_medicineRemainingSeconds % 60}s',
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color?.withAlpha(
                              204,
                            ),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Course Duration Progress Bar with Animation
                if (reminder.courseValue > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Course Progress',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.textTheme.bodySmall?.color
                                    ?.withAlpha(179),
                              ),
                            ),
                            Text(
                              reminder.getCourseDurationText(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isCompleted
                                    ? Colors.teal
                                    : (reminder.courseStartDate == null
                                          ? Colors.orange
                                          : Colors.deepPurpleAccent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (reminder.courseStartDate == null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: Colors.orange,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Start date not set. Press START to begin course.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit_calendar,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                  onPressed: () => _showAddEditMedicineDialog(
                                    reminder: reminder,
                                  ),
                                  tooltip: 'Set start date manually',
                                ),
                              ],
                            ),
                          )
                        else
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0.0,
                              end: reminder.courseProgress,
                            ),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: value,
                                  minHeight: 8,
                                  backgroundColor:
                                      theme.brightness == Brightness.dark
                                      ? Colors.white12
                                      : Colors.black12,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCompleted
                                        ? Colors.teal
                                        : (value > 0.75
                                              ? Colors.orange
                                              : Colors.deepPurpleAccent),
                                  ),
                                ),
                              );
                            },
                          ),
                        if (reminder.courseStartDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Started: ${_formatDate(reminder.courseStartDate!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withAlpha(153),
                                  ),
                                ),
                                if (!isCompleted)
                                  Text(
                                    'End: ${_formatDate(reminder.courseStartDate!.add(Duration(days: reminder.totalCourseDays)))}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withAlpha(153),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _calculateCourseDays(int value, CourseUnit unit) {
    if (value <= 0) return 0;
    switch (unit) {
      case CourseUnit.days:
        return value;
      case CourseUnit.months:
        return value * 30;
      case CourseUnit.years:
        return value * 365;
    }
  }

  Future<void> _showAddEditMedicineDialog({MedicineReminder? reminder}) async {
    final isEditing = reminder != null;
    final formKey = GlobalKey<FormState>();
    String medicineName = reminder?.medicineName ?? '';
    ReminderType reminderType = reminder?.reminderType ?? ReminderType.meal;
    Set<MealTime> mealTimes = reminder?.mealTimes ?? {MealTime.morning};
    MealRelation mealRelation = reminder?.mealRelation ?? MealRelation.after;
    int minutesBefore = reminder?.minutesBefore ?? 30;
    int intervalHours = reminder?.intervalHours ?? 4;
    int courseValue = reminder?.courseValue ?? 0;
    CourseUnit courseUnit = reminder?.courseUnit ?? CourseUnit.days;
    DateTime? courseStartDate = reminder?.courseStartDate;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.95, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Icon(
                      isEditing ? Icons.edit_note : Icons.add_box,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(isEditing ? 'Edit Reminder' : 'Add Reminder'),
                ],
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: medicineName,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name',
                          prefixIcon: Icon(Icons.medication),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                        onSaved: (value) => medicineName = value!,
                      ),
                      DropdownButtonFormField<ReminderType>(
                        value: reminderType,
                        decoration: const InputDecoration(
                          labelText: 'Reminder Type',
                          prefixIcon: Icon(Icons.alarm),
                        ),
                        items: ReminderType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.name.capitalize()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setStateDialog(() => reminderType = value!),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Timing',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: reminderType == ReminderType.meal
                            ? Column(
                                key: const ValueKey('mealSection'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: MealTime.values.map((time) {
                                        final selected = mealTimes.contains(
                                          time,
                                        );
                                        return FilterChip(
                                          label: Text(time.name.capitalize()),
                                          selected: selected,
                                          selectedColor: Colors.deepPurpleAccent
                                              .withValues(alpha: 0.15),
                                          checkmarkColor:
                                              Colors.deepPurpleAccent,
                                          side: BorderSide(
                                            color: selected
                                                ? Colors.deepPurpleAccent
                                                : Colors.grey.shade400,
                                          ),
                                          onSelected: (val) {
                                            setStateDialog(() {
                                              if (val) {
                                                mealTimes.add(time);
                                              } else {
                                                mealTimes.remove(time);
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<MealRelation>(
                                    value: mealRelation,
                                    decoration: const InputDecoration(
                                      labelText: 'Before/After Meal',
                                      prefixIcon: Icon(Icons.restaurant),
                                    ),
                                    items: MealRelation.values
                                        .map(
                                          (rel) => DropdownMenuItem(
                                            value: rel,
                                            child: Text(rel.name.capitalize()),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setStateDialog(
                                      () => mealRelation = value!,
                                    ),
                                  ),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: mealRelation == MealRelation.before
                                        ? Padding(
                                            key: const ValueKey(
                                              'minutesBefore',
                                            ),
                                            padding: const EdgeInsets.only(
                                              top: 8.0,
                                            ),
                                            child: TextFormField(
                                              initialValue: minutesBefore
                                                  .toString(),
                                              decoration: const InputDecoration(
                                                labelText:
                                                    'Minutes Before Meal',
                                                prefixIcon: Icon(Icons.timer),
                                              ),
                                              keyboardType:
                                                  TextInputType.number,
                                              onSaved: (value) =>
                                                  minutesBefore =
                                                      int.tryParse(value!) ??
                                                      30,
                                            ),
                                          )
                                        : const SizedBox.shrink(
                                            key: ValueKey('noMinutesBefore'),
                                          ),
                                  ),
                                ],
                              )
                            : Column(
                                key: const ValueKey('intervalSection'),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextFormField(
                                    initialValue: intervalHours.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Interval (in hours)',
                                      prefixIcon: Icon(Icons.schedule),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (v) =>
                                        (int.tryParse(v ?? '') ?? 0) <= 0
                                        ? 'Must be > 0'
                                        : null,
                                    onSaved: (value) => intervalHours =
                                        int.tryParse(value!) ?? 4,
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Course Duration',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: courseValue.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Course Duration',
                                hintText: 'e.g. 7 (0 = continuous)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                if (n == null || n < 0) {
                                  return 'Enter 0 or more';
                                }
                                return null;
                              },
                              onSaved: (v) =>
                                  courseValue = int.tryParse(v ?? '0') ?? 0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<CourseUnit>(
                              value: courseUnit,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.straighten),
                              ),
                              items: CourseUnit.values
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(
                                        u.name[0].toUpperCase() +
                                            u.name.substring(1),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (u) =>
                                  setStateDialog(() => courseUnit = u!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Course Start Date Picker
                      if (courseValue > 0)
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: courseStartDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              helpText: 'Select Course Start Date',
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Colors.deepPurpleAccent,
                                      onPrimary: Colors.white,
                                      surface: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              setStateDialog(() {
                                courseStartDate = pickedDate;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Course Start Date (Optional)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(
                                Icons.event,
                                color: Colors.deepPurpleAccent,
                              ),
                              suffixIcon: courseStartDate != null
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        setStateDialog(() {
                                          courseStartDate = null;
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            child: Text(
                              courseStartDate != null
                                  ? _formatDate(courseStartDate!)
                                  : 'Tap to select date (auto-sets on start)',
                              style: TextStyle(
                                color: courseStartDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      if (courseValue > 0 && courseStartDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.teal,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Course will end on: ${_formatDate(courseStartDate!.add(Duration(days: _calculateCourseDays(courseValue, courseUnit))))}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      if (reminderType == ReminderType.meal &&
                          mealTimes.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select at least one meal time',
                            ),
                          ),
                        );
                        return;
                      }
                      formKey.currentState!.save();
                      final newReminder = MedicineReminder(
                        id:
                            reminder?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        medicineName: medicineName,
                        reminderType: reminderType,
                        mealTimes: mealTimes,
                        mealRelation: mealRelation,
                        minutesBefore: minutesBefore,
                        intervalHours: intervalHours,
                        courseValue: courseValue,
                        courseUnit: courseUnit,
                        // Use user-selected date or preserve existing
                        courseStartDate:
                            courseStartDate ?? reminder?.courseStartDate,
                      );
                      if (isEditing) {
                        setState(() {
                          final index = _medicineReminders.indexWhere(
                            (r) => r.id == newReminder.id,
                          );
                          if (index != -1) {
                            _medicineReminders[index] = newReminder;
                          }
                        });
                      } else {
                        _addMedicineReminder(newReminder);
                      }
                      _saveMedicineReminders(); // Save after editing or adding
                      Navigator.of(context).pop();
                    }
                  },
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _exerciseHeader() {
    String subtitle = 'General Wellness';
    if (_bmi != null) {
      if (_bmi! < 18.5) {
        subtitle = 'Strength Building Exercises';
      } else if (_bmi! < 25) {
        subtitle = 'Balanced Fitness Routine';
      } else if (_bmi! < 30) {
        subtitle = 'Low-Impact Cardio Focus';
      } else {
        subtitle = 'Gentle Movement Exercises';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Break Exercise Suggestions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              _bmi != null ? Icons.check_circle : Icons.info_outline,
              color: _bmi != null ? Colors.deepPurple[400] : Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: _bmi != null ? Colors.deepPurple[300] : Colors.white70,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _exerciseTile(Map<String, dynamic> e) {
    return Card(
      color: const Color.fromRGBO(255, 255, 255, 0.05),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(e['icon'] as IconData, color: Colors.white, size: 34),
        title: Text(
          e['title'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e['description'] as String,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              'Duration: ${(e['duration_seconds'] as int)} sec • Reps: ${(e['reps'] as int)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ExerciseDemoPage(exercise: e)),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: const Text('Demo'),
        ),
      ),
    );
  }
}

class ExerciseDemoPage extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const ExerciseDemoPage({super.key, required this.exercise});

  @override
  State<ExerciseDemoPage> createState() => _ExerciseDemoPageState();
}

class _ExerciseDemoPageState extends State<ExerciseDemoPage>
    with TickerProviderStateMixin {
  AnimationController? _pulseController;
  int _currentRep = 0;
  int _secondsLeft = 0;
  Timer? _repTimer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.exercise['duration_seconds'];
    _pulseController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 800),
          lowerBound: 0.95,
          upperBound: 1.05,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _pulseController?.reverse();
          } else if (status == AnimationStatus.dismissed) {
            _pulseController?.forward();
          }
        });
  }

  void _startDemo() {
    _stopDemo();
    _currentRep = 1;
    _secondsLeft = widget.exercise['duration_seconds'];
    _pulseController?.forward(from: 0);
    _repTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsLeft -= 1;
        if (_secondsLeft <= 0) {
          if (_currentRep >= widget.exercise['reps']) {
            _stopDemo();

            // Save exercise completion to history
            FirebaseService.saveExerciseHistory(
              exerciseName: widget.exercise['title'],
              durationSeconds:
                  widget.exercise['duration_seconds'] * widget.exercise['reps'],
            );

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Exercise complete')));
          } else {
            _currentRep += 1;
            _secondsLeft = widget.exercise['duration_seconds'];
          }
        }
      });
    });
  }

  void _stopDemo() {
    _repTimer?.cancel();
    _repTimer = null;
    _pulseController?.stop();
    _currentRep = 0;
    _secondsLeft = widget.exercise['duration_seconds'];
    setState(() {});
  }

  @override
  void dispose() {
    _repTimer?.cancel();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise['title']),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _pulseController!,
              builder: (context, child) {
                final scale = _pulseController?.value ?? 1.0;
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                height: 140,
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentRep > 0
                          ? 'Rep $_currentRep/${widget.exercise['reps']}'
                          : '${widget.exercise['reps']} reps',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentRep > 0
                          ? '$_secondsLeft s'
                          : '${widget.exercise['duration_seconds']}s',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Instructions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.exercise['instructions'].map(
              (s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 18, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _startDemo,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _stopDemo,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// --- Data Models for Medicine Reminder ---

enum ReminderType { meal, interval }

enum MealTime { morning, afternoon, night }

enum MealRelation { before, after }

enum CourseUnit { days, months, years }

class MedicineReminder {
  final String id;
  final String medicineName;
  final ReminderType reminderType;
  final Set<MealTime> mealTimes; // allow multiple meals per day
  final MealRelation mealRelation;
  final int minutesBefore;
  final int intervalHours;
  bool isRunning;

  // Course duration: value + unit (0 value means continuous)
  final int courseValue; // numeric value entered by user
  final CourseUnit courseUnit; // days, months, years
  DateTime? courseStartDate;

  MedicineReminder({
    required this.id,
    required this.medicineName,
    this.reminderType = ReminderType.meal,
    Set<MealTime>? mealTimes,
    this.mealRelation = MealRelation.after,
    this.minutesBefore = 30,
    this.intervalHours = 4,
    this.isRunning = false,
    this.courseValue = 0, // Default to continuous
    this.courseUnit = CourseUnit.days,
    this.courseStartDate,
  }) : mealTimes = mealTimes ?? {MealTime.morning};

  // Convert a MedicineReminder into a Map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'medicineName': medicineName,
    'reminderType': reminderType.index,
    'mealTimes': mealTimes.map((m) => m.index).toList(),
    'mealRelation': mealRelation.index,
    'minutesBefore': minutesBefore,
    'intervalHours': intervalHours,
    'isRunning': isRunning,
    'courseValue': courseValue,
    'courseUnit': courseUnit.index,
    'courseStartDate': courseStartDate?.toIso8601String(),
  };

  // Create a MedicineReminder from a map.
  factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    return MedicineReminder(
      id: json['id'],
      medicineName: json['medicineName'],
      reminderType: ReminderType.values[json['reminderType']],
      mealTimes: json.containsKey('mealTimes')
          ? (json['mealTimes'] as List)
                .map((i) => MealTime.values[i as int])
                .toSet()
          : {
              // backward compatibility single mealTime
              MealTime.values[(json['mealTime'] ?? 0) as int],
            },
      mealRelation: MealRelation.values[json['mealRelation']],
      minutesBefore: json['minutesBefore'],
      intervalHours: json['intervalHours'],
      isRunning: json['isRunning'] ?? false,
      // Backward compatibility: if old key exists, use it as days
      courseValue: json.containsKey('courseValue')
          ? (json['courseValue'] ?? 0)
          : (json['courseDurationDays'] ?? 0),
      courseUnit: json.containsKey('courseUnit')
          ? CourseUnit.values[json['courseUnit'] ?? 0]
          : CourseUnit.days,
      courseStartDate: json['courseStartDate'] != null
          ? DateTime.parse(json['courseStartDate'])
          : null,
    );
  }

  // Compute total days for current course (approximate months=30, years=365)
  int get totalCourseDays {
    if (courseValue <= 0) return 0; // continuous
    switch (courseUnit) {
      case CourseUnit.days:
        return courseValue;
      case CourseUnit.months:
        return courseValue * 30;
      case CourseUnit.years:
        return courseValue * 365;
    }
  }

  // Get how many days have elapsed since course started
  int get daysElapsed {
    if (courseStartDate == null) return 0;
    return DateTime.now().difference(courseStartDate!).inDays;
  }

  // Get how many days are remaining in the course
  int get daysRemaining {
    final total = totalCourseDays;
    if (total == 0) return 0; // continuous
    final elapsed = daysElapsed;
    final remaining = total - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  // Get course completion percentage (0.0 to 1.0)
  double get courseProgress {
    final total = totalCourseDays;
    if (total == 0) return 0.0; // continuous
    if (courseStartDate == null) return 0.0;
    final elapsed = daysElapsed;
    if (elapsed >= total) return 1.0; // completed
    return elapsed / total;
  }

  bool get isCourseCompleted {
    final days = totalCourseDays;
    if (courseStartDate == null || days == 0) {
      return false; // Not started or continuous
    }
    return daysElapsed >= days;
  }

  // Get formatted string for course status
  String getCourseDurationText() {
    if (courseValue <= 0) return 'Continuous (No end date)';

    if (courseStartDate == null) {
      return 'Course: $courseValue ${courseUnit.name} (Not started)';
    }

    final remaining = daysRemaining;
    if (remaining == 0) {
      return '✅ Course completed!';
    }

    return '$remaining days remaining (${(courseProgress * 100).toStringAsFixed(0)}% done)';
  }

  String getTimingDetails() {
    if (reminderType == ReminderType.interval) {
      return 'Every $intervalHours hours';
    } else {
      final meals = mealTimes
          .map((m) => m.name.capitalize())
          .toList()
          .join(', ');
      String details = '$meals - ${mealRelation.name.capitalize()} meal';
      if (mealRelation == MealRelation.before) {
        details += ' ($minutesBefore mins before)';
      }
      return details;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
