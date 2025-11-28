import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import 'services/firebase_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Durations
  int pomodoro = 25;
  int shortBreak = 5;
  int longBreak = 15;

  // Color themes
  final List<Color> themes = [
    Colors.red,
    Colors.green.shade200,
    Colors.teal.shade200,
    Colors.deepPurple.shade200,
    Colors.purple,
    Colors.green,
    Colors.grey,
    Colors.teal,
    Colors.blue,
    Colors.blueGrey,
    Colors.cyan,
    Colors.orange,
    Colors.brown,
    Colors.black87,
  ];
  Color selectedTheme = Colors.teal;

  // Sound themes
  bool alarmSound = true;
  bool notificationSound = false;

  // Other Preferences
  int pomodorosUntilLongBreak = 4;
  int dailyGoal = 8;
  bool vibrate = true;
  bool autoStartBreaks = true;
  bool autoStartPomodoros = false;
  bool showNotification = true;
  bool keepAwake = true;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadSettings();
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
  }

  Future<void> _requestNotificationPermission() async {
    final permission = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            permission == true
                ? '✅ Notification permission granted!'
                : '❌ Notification permission denied',
          ),
          backgroundColor: permission == true ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notification channel',
        importance: Importance.max,
        priority: Priority.max,
        enableVibration: vibrate,
        vibrationPattern: vibrate
            ? Int64List.fromList([0, 1000, 400, 1000])
            : null,
        playSound: alarmSound || notificationSound,
        styleInformation: const BigTextStyleInformation(
          'This is a test notification to check if notifications are working properly!',
          contentTitle: '🔔 Test Notification',
        ),
      );

      final iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentSound: alarmSound || notificationSound,
        presentBadge: true,
      );

      await _notificationsPlugin.show(
        999, // Test notification ID
        '🔔 Test Notification',
        'This is a test notification!',
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Test notification sent! Check your notification bar.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Notification error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pomodoro = prefs.getInt('pomodoro_duration') ?? 25;
      shortBreak = prefs.getInt('short_break_duration') ?? 5;
      longBreak = prefs.getInt('long_break_duration') ?? 15;
      alarmSound = prefs.getBool('alarm_sound') ?? true;
      notificationSound = prefs.getBool('notification_sound') ?? false;
      vibrate = prefs.getBool('vibrate') ?? true;
      autoStartBreaks = prefs.getBool('auto_start_breaks') ?? true;
      autoStartPomodoros = prefs.getBool('auto_start_pomodoros') ?? false;
      showNotification = prefs.getBool('show_notification') ?? true;
      keepAwake = prefs.getBool('keep_awake') ?? true;
      pomodorosUntilLongBreak = prefs.getInt('pomodoros_until_long_break') ?? 4;
      dailyGoal = prefs.getInt('daily_goal') ?? 8;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pomodoro_duration', pomodoro);
    await prefs.setInt('short_break_duration', shortBreak);
    await prefs.setInt('long_break_duration', longBreak);
    await prefs.setBool('alarm_sound', alarmSound);
    await prefs.setBool('notification_sound', notificationSound);
    await prefs.setBool('vibrate', vibrate);
    await prefs.setBool('auto_start_breaks', autoStartBreaks);
    await prefs.setBool('auto_start_pomodoros', autoStartPomodoros);
    await prefs.setBool('show_notification', showNotification);
    await prefs.setBool('keep_awake', keepAwake);
    await prefs.setInt('pomodoros_until_long_break', pomodorosUntilLongBreak);
    await prefs.setInt('daily_goal', dailyGoal);
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: Switch(
        activeColor: Colors.white,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6EA98D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6EA98D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () async {
            await _saveSettings();
            if (!context.mounted) return;
            Navigator.pop(context, {
              'pomodoro': pomodoro,
              'shortBreak': shortBreak,
              'longBreak': longBreak,
              'theme': selectedTheme,
              'alarmSound': alarmSound,
              'notificationSound': notificationSound,
              'vibrate': vibrate,
              'pomodorosUntilLongBreak': pomodorosUntilLongBreak,
              'dailyGoal': dailyGoal,
              'autoStartBreaks': autoStartBreaks,
              'autoStartPomodoros': autoStartPomodoros,
              'showNotification': showNotification,
              'keepAwake': keepAwake,
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _saveSettings();
              if (!context.mounted) return;
              Navigator.pop(context, {
                'pomodoro': pomodoro,
                'shortBreak': shortBreak,
                'longBreak': longBreak,
                'theme': selectedTheme,
                'alarmSound': alarmSound,
                'notificationSound': notificationSound,
                'vibrate': vibrate,
                'pomodorosUntilLongBreak': pomodorosUntilLongBreak,
                'dailyGoal': dailyGoal,
                'autoStartBreaks': autoStartBreaks,
                'autoStartPomodoros': autoStartPomodoros,
                'showNotification': showNotification,
                'keepAwake': keepAwake,
              });
            },
            child: const Text('SAVE', style: TextStyle(color: Colors.white)),
          ),
        ],
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Durations
            const Text(
              "DURATIONS",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            // Fixed layout: first row has 2 boxes, second row has 1 centered box.
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.9,
                          child: _durationBox(
                            "POMODORO",
                            pomodoro,
                            (v) => setState(() => pomodoro = v),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.9,
                          child: _durationBox(
                            "BREAK",
                            shortBreak,
                            (v) => setState(() => shortBreak = v),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.95,
                    child: _durationBox(
                      "LONG BREAK",
                      longBreak,
                      (v) => setState(() => longBreak = v),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Color themes
            const Text(
              "COLOR THEMES",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: themes.map((color) {
                bool isSelected = selectedTheme == color;
                return GestureDetector(
                  onTap: () => setState(() => selectedTheme = color),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Sound themes
            const Text(
              "SOUND THEMES",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SwitchListTile(
              title: const Text(
                "Notification Sound",
                style: TextStyle(color: Colors.white),
              ),
              value: notificationSound,
              activeColor: Colors.white,
              onChanged: (val) => setState(() => notificationSound = val),
            ),
            SwitchListTile(
              title: const Text(
                "Alarm Sound",
                style: TextStyle(color: Colors.white),
              ),
              value: alarmSound,
              activeColor: Colors.white,
              onChanged: (val) => setState(() => alarmSound = val),
            ),
            const SizedBox(height: 20),

            // Notification Testing Section
            const Text(
              "NOTIFICATION SETTINGS",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: _requestNotificationPermission,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('Request Notification Permission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _testNotification,
                    icon: const Icon(Icons.notifications),
                    label: const Text('Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If notifications aren\'t working, tap "Request Permission" first, then test.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // History Section
            const Text(
              "HISTORY & STATS",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history, color: Colors.white),
                ),
                title: const Text(
                  "View History",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Track your productivity sessions",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Other Preferences
            const Text(
              "OTHER PREFERENCES",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            _buildToggle(
              "Vibrate",
              vibrate,
              (val) => setState(() => vibrate = val),
            ),
            _buildToggle(
              "Autostart Breaks",
              autoStartBreaks,
              (val) => setState(() => autoStartBreaks = val),
            ),
            _buildToggle(
              "Autostart Pomodoros",
              autoStartPomodoros,
              (val) => setState(() => autoStartPomodoros = val),
            ),
            _buildToggle(
              "Show Notification",
              showNotification,
              (val) => setState(() => showNotification = val),
            ),
            _buildToggle(
              "Keep Phone Awake",
              keepAwake,
              (val) => setState(() => keepAwake = val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationBox(String label, int value, [ValueChanged<int>? onChanged]) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                "$value",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                      maxWidth: 24,
                      maxHeight: 24,
                    ),
                    iconSize: 16,
                    icon: const Icon(Icons.remove, color: Colors.white),
                    onPressed: onChanged == null
                        ? null
                        : () {
                            if (value > 1) onChanged(value - 1);
                          },
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                      maxWidth: 24,
                      maxHeight: 24,
                    ),
                    iconSize: 16,
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: onChanged == null
                        ? null
                        : () {
                            onChanged(value + 1);
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

// History Page
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _sessions = [];
  final Map<String, int> _stats = {
    'totalSessions': 0,
    'totalMinutes': 0,
    'todaySessions': 0,
    'weekSessions': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Fade animation for stats cards
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _loadHistory();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final sessions = await FirebaseService.getHistory();

      setState(() {
        _sessions = sessions;

        // Calculate stats
        _stats['totalSessions'] = _sessions.length;
        _stats['totalMinutes'] = _sessions.fold(
          0,
          (sum, s) => sum + (s['duration'] as int),
        );

        final today = DateTime.now();
        _stats['todaySessions'] = _sessions.where((s) {
          final date = s['timestamp'] as DateTime;
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).length;

        final weekAgo = today.subtract(const Duration(days: 7));
        _stats['weekSessions'] = _sessions.where((s) {
          final date = s['timestamp'] as DateTime;
          return date.isAfter(weekAgo);
        }).length;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading history: $e')));
      }
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History?'),
        content: const Text(
          'This will delete all your session history from Firebase. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseService.clearHistory();
        _loadHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('History cleared from Firebase')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error clearing history: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6EA98D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6EA98D),
        elevation: 0,
        title: const Text(
          "History & Stats",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _clearHistory,
            tooltip: 'Clear History',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'STATS'),
            Tab(text: 'TODAY'),
            Tab(text: 'ALL'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildStatsTab(), _buildTodayTab(), _buildAllTab()],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Total stats cards with staggered animation
            Row(
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: _buildStatCard(
                      Icons.timer,
                      '${_stats['totalSessions']}',
                      'Total Sessions',
                      Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: _buildStatCard(
                      Icons.access_time,
                      '${(_stats['totalMinutes']! / 60).toStringAsFixed(1)}h',
                      'Total Time',
                      Colors.purple,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: _buildStatCard(
                      Icons.today,
                      '${_stats['todaySessions']}',
                      'Today',
                      Colors.teal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: _buildStatCard(
                      Icons.calendar_today,
                      '${_stats['weekSessions']}',
                      'This Week',
                      Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress ring with pulse animation
            if (_stats['totalSessions']! > 0)
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).toInt()),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Productivity Score',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 1500),
                        tween: Tween(
                          begin: 0.0,
                          end: (_stats['totalSessions']! / 100).clamp(0.0, 1.0),
                        ),
                        curve: Curves.easeInOutCubic,
                        builder: (context, value, child) {
                          return SizedBox(
                            width: 150,
                            height: 150,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 12,
                                  backgroundColor: Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.orange,
                                      ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TweenAnimationBuilder<int>(
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                      tween: IntTween(
                                        begin: 0,
                                        end: (_stats['totalSessions']! * 1.5)
                                            .toInt(),
                                      ),
                                      builder: (context, value, child) {
                                        return Text(
                                          '$value',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                    const Text(
                                      'points',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Keep going! 🔥',
                        style: TextStyle(
                          color: Colors.orange.shade200,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    final today = DateTime.now();
    final todaySessions = _sessions.where((s) {
      final date = s['timestamp'] as DateTime;
      return date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
    }).toList();

    return todaySessions.isEmpty
        ? Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.9 + (value * 0.1),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 1.0, end: 1.1),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    onEnd: () => setState(() {}),
                    child: Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.white.withAlpha((0.3 * 255).toInt()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No sessions today',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: todaySessions.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 50)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: _buildSessionCard(todaySessions[index]),
              );
            },
          );
  }

  Widget _buildAllTab() {
    return _sessions.isEmpty
        ? Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.9 + (value * 0.1),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween(begin: 1.0, end: 1.1),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    onEnd: () => setState(() {}),
                    child: Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.white.withAlpha((0.3 * 255).toInt()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No history yet',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete a session to see it here!',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _sessions.length,
            itemBuilder: (context, index) {
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 400 + (index * 50)),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: _buildSessionCard(_sessions[index]),
              );
            },
          );
  }

  Widget _buildStatCard(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final type = session['type'] as String;
    final duration = session['duration'] as int;
    final timestamp = session['timestamp'] as DateTime;

    IconData icon;
    Color color;
    String typeLabel;

    if (type == 'pomodoro') {
      icon = Icons.timer;
      color = Colors.orange;
      typeLabel = 'Pomodoro';
    } else if (type == 'short') {
      icon = Icons.coffee;
      color = Colors.blue;
      typeLabel = 'Short Break';
    } else {
      icon = Icons.weekend;
      color = Colors.purple;
      typeLabel = 'Long Break';
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha((0.2 * value * 255).toInt()),
                blurRadius: 8 * value,
                offset: Offset(0, 4 * value),
              ),
            ],
          ),
          child: Row(
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, scaleValue, child) {
                  return Transform.scale(scale: scaleValue, child: child);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$duration minutes',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(timestamp),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(timestamp),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
