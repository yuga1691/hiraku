import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> initialize({String? userId}) async {
    if (userId == null || userId.isEmpty) {
      return;
    }
    await setUserId(userId);
  }

  Future<void> setUserId(String userId) async {
    if (userId.isEmpty) {
      return;
    }
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('Analytics setUserId failed: $e');
    }
  }

  Future<void> logOnboardingCompleted() async {
    await _logEvent('onboarding_completed');
  }

  Future<void> logAppRegisterCompleted({
    required String packageName,
  }) async {
    await _logEvent(
      'app_register_completed',
      parameters: {
        'package_name': packageName,
      },
    );
  }

  Future<void> logTestAppDetailOpened({
    required String appId,
    required String packageName,
    required String targetUserId,
  }) async {
    await _logEvent(
      'test_app_detail_opened',
      parameters: _compactParameters({
        'app_id': appId,
        'package_name': packageName,
        'target_user_id': targetUserId,
      }),
    );
  }

  Future<void> logTestStoreOpened({
    required String appId,
    required String packageName,
    required String targetUserId,
  }) async {
    await _logEvent(
      'test_store_opened',
      parameters: _compactParameters({
        'app_id': appId,
        'package_name': packageName,
        'target_user_id': targetUserId,
      }),
    );
  }

  Future<void> logTestCompleted({
    required String appId,
    required String packageName,
    required String targetUserId,
  }) async {
    await _logEvent(
      'test_completed',
      parameters: _compactParameters({
        'app_id': appId,
        'package_name': packageName,
        'target_user_id': targetUserId,
      }),
    );
  }

  Future<void> logBoostActivated() async {
    await _logEvent('boost_activated');
  }

  Future<void> logNotificationPermissionGranted() async {
    await _logEvent('notification_permission_granted');
  }

  Future<void> logDiscordJoinConfirmYes() async {
    await _logEvent('discord_join_confirm_yes');
  }

  Future<void> _logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('Analytics event "$name" failed: $e');
    }
  }

  Map<String, Object> _compactParameters(Map<String, Object?> input) {
    final result = <String, Object>{};
    for (final entry in input.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      if (value is String && value.trim().isEmpty) {
        continue;
      }
      result[entry.key] = value;
    }
    return result;
  }
}
