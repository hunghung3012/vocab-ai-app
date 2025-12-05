import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_ai/services/local_notification/local_notification_service.dart';


class NotificationProvider with ChangeNotifier {
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  NotificationProvider() {
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('notifications_enabled') ?? false;

    // Nếu đã bật từ trước, start lại notification
    if (_isEnabled) {
      await LocalNotificationService().startRepeatingNotificationEvery20Seconds();
    }

    notifyListeners();
  }

  Future<void> toggleNotifications(bool value) async {
    _isEnabled = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);

    if (value) {
      // Bật notification
      await LocalNotificationService().startRepeatingNotificationEvery20Seconds();
    } else {
      // Tắt notification
      LocalNotificationService().stopRepeatingNotification();
      await LocalNotificationService().cancelAllNotifications();
    }
  }
}