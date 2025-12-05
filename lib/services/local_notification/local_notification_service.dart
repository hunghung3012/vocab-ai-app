import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
  LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  static const String channelId = 'vocab_ai_daily_channel';
  static const String channelName = 'VocabAI Daily Reminder';
  static const String channelDescription = 'Daily vocabulary reminder at 8 AM';

  bool _isInitialized = false;
  Timer? _repeatingTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    final settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Request permission
    await Permission.notification.request();

    _isInitialized = true;
  }

  /// Notification hàng ngày lúc 8AM: "Time to review your vocabulary! 📚"
  Future<void> scheduleDailyVocabReminder() async {
    await initialize();

    await _notifications.zonedSchedule(
      0, // notification id
      'VocabAI 📚',
      'Time to review your vocabulary! Keep your streak going! 🔥',
      _nextInstanceOfTime(8,0),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Test: Gửi notification ngay lập tức
  Future<void> sendTestNotification() async {
    await initialize();

    final now = DateTime.now();
    await _notifications.show(
      now.millisecondsSinceEpoch ~/ 1000,
      'VocabAI Test 🧪',
      'This is a test notification!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  /// Test: Gửi notification mỗi 20 giây (cho testing)
  Future<void> startRepeatingNotificationEvery20Seconds() async {
    await initialize();

    _repeatingTimer?.cancel();

    // Gửi ngay
    await _sendRepeatingNotification();

    // Lặp lại mỗi 20 giây
    _repeatingTimer = Timer.periodic(
      const Duration(seconds: 20),
          (timer) async {
        await _sendRepeatingNotification();
      },
    );
  }

  Future<void> _sendRepeatingNotification() async {
    final now = DateTime.now();
    await _notifications.show(
      now.millisecondsSinceEpoch ~/ 1000,
      'VocabAI Reminder 🔔',
      'Time to study! You have decks waiting for review.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }

  void stopRepeatingNotification() {
    _repeatingTimer?.cancel();
    _repeatingTimer = null;
  }

  /// Hủy tất cả notifications đã schedule
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour, // 8 AM
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  void _handleNotificationTap(NotificationResponse details) {
    // TODO: Navigate to specific screen when user taps notification
    // Example: Navigator.pushNamed(context, '/decks');
  }
}