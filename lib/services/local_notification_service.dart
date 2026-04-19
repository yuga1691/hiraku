import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _notificationId = 0;

  Future<void> initialize() async {
    if (_initialized) return;
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettingsDarwin = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );
    await _plugin.initialize(initializationSettings);
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'tester_joined_channel',
        'Tester Notifications',
        description: 'Notification when a new tester joins your app.',
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!_initialized) {
      await initialize();
    }
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
    >();
    final androidGranted = await androidPlugin?.requestNotificationsPermission();
    if (androidGranted == true) {
      return true;
    }

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosGranted == true) {
      return true;
    }

    final macosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final macosGranted = await macosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return macosGranted ?? false;
  }

  Future<void> showTesterJoinedNotification({
    required String testerName,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final displayName =
        testerName.trim().isEmpty ? '\u8ab0\u304b' : testerName.trim();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'tester_joined_channel',
        'Tester Notifications',
        channelDescription: 'Notification when a new tester joins your app.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.show(
      _notificationId++,
      'hiraku',
      '$displayName\u3055\u3093\u304c\u3042\u306a\u305f\u306e\u30c6\u30b9\u30bf\u30fc\u306b\u306a\u308a\u307e\u3057\u305f\uff01',
      details,
    );
  }
}
