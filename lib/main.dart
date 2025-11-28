import 'setting.dart';
import 'booklist.dart';
import 'motivation.dart';
import 'notepad.dart';
import 'pomodoro_logo.dart';
import 'health_integration.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/top_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatefulWidget {
  const PomodoroApp({super.key});

  @override
  State<PomodoroApp> createState() => _PomodoroAppState();
}

class _PomodoroAppState extends State<PomodoroApp> {
  Color themeColor = const Color(0xFF6EA98D);

  void updateTheme(Color color) {
    setState(() {
      themeColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: themeColor,
        useMaterial3: true,
      ),
      home: PomodoroPage(onThemeChanged: updateTheme, themeColor: themeColor),
      debugShowCheckedModeBanner: false,
      routes: {
        '/booklist': (context) => const BookListPage(),
        '/motivational': (context) => const MotivationPage(),
        '/health': (context) => const HealthIntegrationPage(),
        '/notepad': (context) => const NotepadPage(),
      },
    );
  }
}

enum PomodoroMode { pomodoro, shortBreak, longBreak }

class PomodoroPage extends StatefulWidget {
  final Color? themeColor;
  final void Function(Color)? onThemeChanged;

  const PomodoroPage({super.key, this.themeColor, this.onThemeChanged});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage>
    with TickerProviderStateMixin {
  Duration pomodoroDuration = const Duration(minutes: 25);
  Duration shortBreakDuration = const Duration(minutes: 5);
  Duration longBreakDuration = const Duration(minutes: 15);
  late Color themeColor;

  Map<PomodoroMode, Duration> get _durations => {
    PomodoroMode.pomodoro: pomodoroDuration,
    PomodoroMode.shortBreak: shortBreakDuration,
    PomodoroMode.longBreak: longBreakDuration,
  };

  PomodoroMode _currentMode = PomodoroMode.pomodoro;
  late AnimationController _controller;
  Timer? _ticker;
  Duration _remaining = const Duration(minutes: 25);
  bool _isRunning = false;

  // Settings
  bool _alarmSound = true;
  bool _notificationSound = false;
  bool _vibrate = true;
  bool _showNotification = true;

  // Notification and Audio
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer()
    ..setPlayerMode(PlayerMode.lowLatency);

  @override
  void initState() {
    super.initState();
    themeColor = widget.themeColor ?? const Color(0xFF6EA98D);
    _initNotifications();
    _loadSettings();
    _initController();
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

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _alarmSound = prefs.getBool('alarm_sound') ?? true;
        _notificationSound = prefs.getBool('notification_sound') ?? false;
        _vibrate = prefs.getBool('vibrate') ?? true;
        _showNotification = prefs.getBool('show_notification') ?? true;
      });
    } catch (e) {
      // Use defaults
    }
  }

  void _initController() {
    _controller = AnimationController(
      vsync: this,
      duration: _durations[_currentMode],
    );

    _controller.addListener(() {
      if (!mounted) return;
      setState(() {
        final t = _controller.value;
        _remaining = Duration(
          milliseconds: ((1 - t) * _durations[_currentMode]!.inMilliseconds)
              .round(),
        );
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playNotificationSound() async {
    if (!_alarmSound && !_notificationSound) return;

    try {
      // MAXIMUM STRENGTH VIBRATION - Try all methods at once!
      if (_vibrate) {
        // Method 1: HapticFeedback
        HapticFeedback.vibrate();
        HapticFeedback.heavyImpact();

        // Method 2: Vibration package - Simple long vibration
        try {
          await Vibration.vibrate(duration: 3000); // 3 seconds continuous
        } catch (e) {
          debugPrint('Vibration error: $e');
        }
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

  Future<void> _showCompletionNotification() async {
    // Always show notification as requested
    String title = '⏰ Pomodoro Timer Complete!';
    String body = '';

    switch (_currentMode) {
      case PomodoroMode.pomodoro:
        body = '✅ Pomodoro session completed! Time for a break. 🎉';
        break;
      case PomodoroMode.shortBreak:
        body = '✅ Short break finished! Ready to focus? 💪';
        break;
      case PomodoroMode.longBreak:
        body = '✅ Long break finished! Let\'s get back to work! 🚀';
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      'pomodoro_timer_v3',
      'Pomodoro Timer',
      channelDescription: 'Notifications for Pomodoro timer completion',
      importance: Importance.max,
      priority: Priority.max,
      enableVibration: _vibrate,
      vibrationPattern: _vibrate
          ? Int64List.fromList([0, 1000, 400, 1000, 400, 1000])
          : null,
      playSound: _alarmSound || _notificationSound,
      ticker: 'Pomodoro Timer Alert',
      styleInformation: BigTextStyleInformation(body, contentTitle: title),
      enableLights: true,
      ledColor: const Color(0xFF6EA98D),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: false, // Don't show full screen
      category: AndroidNotificationCategory.alarm,
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
      await _notificationsPlugin.show(
        0, // ID 0 for timer notifications
        title,
        body,
        notificationDetails,
      );
      debugPrint('✅ Notification shown: $title');
    } catch (e) {
      debugPrint('❌ Notification error: $e');
    }
  }

  Future<void> _onTimerComplete() async {
    debugPrint('⏰ Timer completed! Mode: ${_currentMode.name}');

    // Save to Firebase
    try {
      await FirebaseService.saveHistorySession({
        'type': _currentMode == PomodoroMode.pomodoro
            ? 'pomodoro'
            : (_currentMode == PomodoroMode.shortBreak ? 'short' : 'long'),
        'duration': _durations[_currentMode]!.inMinutes,
        'timestamp': DateTime.now(),
      });
      debugPrint('✅ Session saved to Firebase');
    } catch (e) {
      debugPrint('❌ Error saving to Firebase: $e');
    }

    // Show notification first (upore status bar e)
    await _showCompletionNotification();

    // In-app animated banner for a nicer heads-up
    if (mounted) {
      TopBannerNotifier.show(
        context,
        title: 'Pomodoro Complete',
        message: _currentMode == PomodoroMode.pomodoro
            ? 'Great job! Take a short break.'
            : (_currentMode == PomodoroMode.shortBreak
                  ? 'Break over. Ready to focus again?'
                  : 'Long break ended. Let\'s get back to work!'),
        color: themeColor,
        icon: Icons.timer,
        duration: const Duration(seconds: 3),
      );
    }

    // Then trigger vibration
    await _triggerVibration();

    // Finally play sound
    await _playNotificationSound();
  }

  // ✅ FIXED: Mode change now resets + auto starts timer instantly
  void _changeMode(PomodoroMode mode) {
    _ticker?.cancel();
    try {
      _controller.stop();
      _controller.reset();
    } catch (_) {}

    setState(() {
      _currentMode = mode;
      _isRunning = false;
      _remaining = _durations[_currentMode]!;
    });

    // 🔄 safely recreate controller with new duration
    try {
      _controller.dispose();
    } catch (_) {}

    _controller = AnimationController(
      vsync: this,
      duration: _durations[_currentMode],
    );

    _controller.addListener(() {
      if (!mounted) return;
      setState(() {
        final t = _controller.value;
        _remaining = Duration(
          milliseconds: ((1 - t) * _durations[_currentMode]!.inMilliseconds)
              .round(),
        );
      });
    });

    // 🚀 start timer if mounted
    if (mounted) _startTimer();
  }

  void _startTimer() {
    if (_isRunning) return;
    if (!mounted) return;
    setState(() => _isRunning = true);
    try {
      // If the controller already has progressed (paused), resume from current
      // value. Otherwise start from 0.
      if (_controller.value > 0 && _controller.value < 1) {
        _controller.forward();
      } else {
        _controller.forward(from: 0);
      }
    } catch (_) {
      setState(() => _isRunning = false);
      return;
    }

    _ticker?.cancel();
    // Update every 100ms for smoother UI (10 times per second)
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) {
        _ticker?.cancel();
        return;
      }
      try {
        // Only setState every 500ms to avoid too many rebuilds
        if (DateTime.now().millisecond % 500 < 100) {
          setState(() {});
        }

        if (_controller.isCompleted) {
          _ticker?.cancel();
          setState(() => _isRunning = false);
          // Trigger notification, sound, and vibration
          _onTimerComplete();
        }
      } catch (_) {}
    });
  }

  void _pauseTimer() {
    if (_isRunning) {
      _controller.stop();
      _ticker?.cancel();
      setState(() => _isRunning = false);
    }
  }

  void _resetTimer() {
    _controller.reset();
    _ticker?.cancel();
    setState(() {
      _remaining = _durations[_currentMode]!;
      _isRunning = false;
    });
  }

  String _formatted(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _modeName() {
    switch (_currentMode) {
      case PomodoroMode.pomodoro:
        return "POMODORO";
      case PomodoroMode.shortBreak:
        return "SHORT BREAK";
      case PomodoroMode.longBreak:
        return "LONG BREAK";
    }
  }

  @override
  Widget build(BuildContext context) {
    final double size = MediaQuery.of(context).size.width * 0.78;
    final progress = _controller.value;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            PomodoroLogo(
              size: 36,
              label: 'Pomodoro',
              imageUrl:
                  'https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/14/a0/b4/14a0b468-7bd9-84a1-f8d7-2413bce12dbe/AppIcon-0-0-1x_U007epad-0-1-85-220.png/512x512bb.jpg',
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );

              if (result != null && result is Map) {
                setState(() {
                  // Durations may be returned as int (minutes) or as Duration.
                  final p = result['pomodoro'];
                  if (p is Duration) {
                    pomodoroDuration = p;
                  } else if (p is int) {
                    pomodoroDuration = Duration(minutes: p);
                  }

                  final s = result['shortBreak'];
                  if (s is Duration) {
                    shortBreakDuration = s;
                  } else if (s is int) {
                    shortBreakDuration = Duration(minutes: s);
                  }

                  final l = result['longBreak'];
                  if (l is Duration) {
                    longBreakDuration = l;
                  } else if (l is int) {
                    longBreakDuration = Duration(minutes: l);
                  }

                  final t = result['theme'];
                  if (t is Color) {
                    themeColor = t;
                    // Notify parent app to update global theme if available
                    try {
                      widget.onThemeChanged?.call(t);
                    } catch (_) {}
                  }

                  // Update settings
                  _alarmSound = result['alarmSound'] ?? _alarmSound;
                  _notificationSound =
                      result['notificationSound'] ?? _notificationSound;
                  _vibrate = result['vibrate'] ?? _vibrate;
                  _showNotification =
                      result['showNotification'] ?? _showNotification;
                });
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: themeColor),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: const [
                    PomodoroLogo(
                      size: 48,
                      imageUrl:
                          'https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/14/a0/b4/14a0b468-7bd9-84a1-f8d7-2413bce12dbe/AppIcon-0-0-1x_U007epad-0-1-85-220.png/512x512bb.jpg',
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Pomodoro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.book),
              title: Text('Book List'),
              onTap: () {
                Navigator.pushNamed(context, '/booklist');
              },
            ),
            ListTile(
              leading: Icon(Icons.health_and_safety),
              title: Text('Health Integration'),
              onTap: () {
                Navigator.pushNamed(context, '/health');
              },
            ),
            ListTile(
              leading: Icon(Icons.lightbulb),
              title: Text('Motivational Speech'),
              onTap: () {
                Navigator.pushNamed(context, '/motivational');
              },
            ),
            ListTile(
              leading: Icon(Icons.note),
              title: Text('Notepad'),
              onTap: () {
                Navigator.pushNamed(context, '/notepad');
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 6,
                children: [
                  _modeButton("Pomodoro", PomodoroMode.pomodoro),
                  _modeButton("Short Break", PomodoroMode.shortBreak),
                  _modeButton("Long Break", PomodoroMode.longBreak),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: _isRunning || _remaining != _durations[_currentMode]
                    ? _buildRunningScreen(size, progress)
                    : _buildPlayScreen(size),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeButton(String label, PomodoroMode mode) {
    final bool active = _currentMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton(
        onPressed: () {
          // Ensure UI updates reliably when switching modes
          setState(() {
            _changeMode(mode);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? Colors.white : Colors.white24,
          foregroundColor: active ? Colors.black : Colors.white,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildPlayScreen(double size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _startTimer,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 6),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 100),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '${_modeName()} ${_durations[_currentMode]!.inMinutes} MIN',
          style: const TextStyle(
            color: Colors.white,
            letterSpacing: 1.5,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRunningScreen(double size, double progress) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _isRunning ? _pauseTimer : _startTimer,
          child: CustomPaint(
            painter: _PomodoroPainter(progress: progress),
            size: Size(size, size),
            child: SizedBox(width: size, height: size),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          _modeName(),
          style: const TextStyle(
            color: Colors.white,
            letterSpacing: 1.5,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatted(_remaining),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _resetTimer,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          child: const Text("RESET"),
        ),
        const SizedBox(height: 20),
        Opacity(
          opacity: 0.7,
          child: Text(
            _isRunning ? 'Tap to pause • Tap again to resume' : 'Tap to start',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _PomodoroPainter extends CustomPainter {
  final double progress;
  _PomodoroPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = max(1, size.width * 0.01)
      ..strokeCap = StrokeCap.round;

    final int tickCount = 24;
    for (int i = 0; i < tickCount; i++) {
      final angle = (i / tickCount) * 2 * pi;
      final inner = Offset(
        center.dx + (radius - size.width * 0.06) * cos(angle - pi / 2),
        center.dy + (radius - size.width * 0.06) * sin(angle - pi / 2),
      );
      final outer = Offset(
        center.dx + (radius - size.width * 0.02) * cos(angle - pi / 2),
        center.dy + (radius - size.width * 0.02) * sin(angle - pi / 2),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..color = Colors.white;
    canvas.drawCircle(
      center,
      radius - size.width * 0.03 - (size.width * 0.06 / 2),
      ringPaint,
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFF3D7A61);
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - size.width * 0.03 - (size.width * 0.06 / 2),
    );
    final startAngle = -pi / 2;
    final sweep = 2 * pi * progress;
    canvas.drawArc(rect, startAngle, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _PomodoroPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
