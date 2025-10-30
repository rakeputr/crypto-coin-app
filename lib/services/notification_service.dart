import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inisialisasi notifikasi
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
    tzdata.initializeTimeZones();
  }

  /// Menampilkan notifikasi langsung (untuk testing manual)
  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'crypto_channel',
          'Crypto Alerts',
          channelDescription: 'Notifikasi perubahan harga crypto',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(0, title, body, details);
  }

  /// Menjadwalkan notifikasi harian otomatis
  static Future<void> scheduleDailyNotification() async {
    await _notificationsPlugin.show(
      1,
      'Pengingat Market Crypto',
      'Cek update harga terbaru hari ini!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminder',
          channelDescription: 'Notifikasi harian untuk cek market crypto',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
