import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiscordWebhookService {
  static const String _discordOptInKey = 'discordOptIn';
  static const String _sentRegisteredAppOnDiscordJoinKey =
      'sentRegisteredAppOnDiscordJoin';
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-northeast1',
  );

  Future<bool> isDiscordOptIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_discordOptInKey) ?? false;
  }

  Future<void> setDiscordOptIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_discordOptInKey, value);
  }

  Future<bool> hasSentRegisteredAppOnDiscordJoin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sentRegisteredAppOnDiscordJoinKey) ?? false;
  }

  Future<void> markRegisteredAppOnDiscordJoinSent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sentRegisteredAppOnDiscordJoinKey, true);
  }

  Future<void> sendDiscordJoinNotification({required String username}) {
    return _sendNotification(
      type: 'join',
      userName: username,
    );
  }

  Future<void> sendRegisteredAppOnDiscordJoinNotification({
    required String username,
    required String appName,
    required String appDescription,
    required String playUrl,
  }) {
    final summary = appDescription.isEmpty
        ? '\uff08\u672a\u5165\u529b\uff09'
        : appDescription;
    return _sendNotification(
      type: 'registered_app_on_join',
      userName: username,
      appName: appName,
      appDescription: summary,
      playUrl: playUrl,
    );
  }

  Future<void> sendAppRegisteredNotification({
    required String appName,
    required String playUrl,
  }) {
    return _sendNotification(
      type: 'app_registered',
      appName: appName,
      playUrl: playUrl,
    );
  }

  Future<void> sendTestJoinedNotification({
    required String username,
    required String appName,
  }) {
    return _sendNotification(
      type: 'test_joined',
      userName: username,
      appName: appName,
    );
  }

  Future<void> sendTestEndedNotification({
    required String username,
    required String appName,
  }) {
    return _sendNotification(
      type: 'test_ended',
      userName: username,
      appName: appName,
    );
  }

  Future<void> _sendNotification({
    required String type,
    String? userName,
    String? appName,
    String? appDescription,
    String? playUrl,
    String? message,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendDiscordNotification');
      final response = await callable.call(<String, dynamic>{
        'type': type,
        ...?userName == null ? null : {'userName': userName},
        ...?appName == null ? null : {'appName': appName},
        ...?appDescription == null ? null : {'appDescription': appDescription},
        ...?playUrl == null ? null : {'playUrl': playUrl},
        ...?message == null ? null : {'message': message},
      });

      final data = response.data;
      if (data is! Map) {
        debugPrint('Discord callable invalid response');
        return;
      }
      final ok = data['ok'] == true;
      if (!ok) {
        final error = data['error'];
        debugPrint('Discord callable failed: $error');
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Discord callable error: ${e.code} ${e.message}');
    } catch (e) {
      debugPrint('Discord callable unexpected error: $e');
    }
  }
}
