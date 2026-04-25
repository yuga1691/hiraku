import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notification_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _adminTopic = 'hiraku_admin';

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  String? _currentUserId;

  Future<void> startForUser(String userId) async {
    await stop();
    if (userId.isEmpty) return;
    _currentUserId = userId;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _messaging.subscribeToTopic('hiraku_all');
    await _syncAdminTopicSubscription(userId);

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(userId: userId, token: token);
    }

    _onTokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      if (_currentUserId == null || token.isEmpty) return;
      await _saveToken(userId: _currentUserId!, token: token);
    });

    _onMessageSubscription = FirebaseMessaging.onMessage.listen((message) async {
      final title = message.notification?.title ?? 'HIRAKU';
      final body = message.notification?.body ?? '';
      if (body.trim().isNotEmpty) {
        await LocalNotificationService.instance.showSimpleNotification(
          title: title,
          body: body,
        );
      }
    });
  }

  Future<void> stop() async {
    await _onMessageSubscription?.cancel();
    await _onTokenRefreshSubscription?.cancel();
    _onMessageSubscription = null;
    _onTokenRefreshSubscription = null;
    _currentUserId = null;
  }

  Future<void> _saveToken({
    required String userId,
    required String token,
  }) async {
    await _db.collection('users').doc(userId).collection('fcmTokens').doc(token).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
      'platform': 'app',
    }, SetOptions(merge: true));
  }

  Future<void> _syncAdminTopicSubscription(String userId) async {
    final snapshot = await _db.collection('users').doc(userId).get();
    final isOfficial = (snapshot.data()?['hasOfficialBadge'] ?? false) as bool;
    if (isOfficial) {
      await _messaging.subscribeToTopic(_adminTopic);
      return;
    }
    await _messaging.unsubscribeFromTopic(_adminTopic);
  }
}
