import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class DiscordWebhookService {
  static const String _discordOptInKey = 'discordOptIn';
  static const String _sentRegisteredAppOnDiscordJoinKey =
      'sentRegisteredAppOnDiscordJoin';

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
    return _postMessage(
      '\u{1F389} $username \u3055\u3093\u304cDiscord\u306b\u53c2\u52a0\u3057\u307e\u3057\u305f',
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
    return _postMessage(
      '\u{1F195} $username \u3055\u3093\u304c\u767b\u9332\u3057\u305f\u30c6\u30b9\u30c8\u30a2\u30d7\u30ea: $appName $playUrl\n'
      '\u30c6\u30b9\u30c8\u6982\u8981: $summary',
    );
  }

  Future<void> sendAppRegisteredNotification({
    required String appName,
    required String playUrl,
  }) {
    return _postMessage(
      '\u{1F195} \u65b0\u3057\u3044\u30c6\u30b9\u30c8\u30a2\u30d7\u30ea\u304c\u767b\u9332\u3055\u308c\u307e\u3057\u305f: $appName $playUrl',
    );
  }

  Future<void> sendTestJoinedNotification({
    required String username,
    required String appName,
  }) {
    return _postMessage(
      '\u{1F389} $username \u304c $appName \u306e\u30c6\u30b9\u30c8\u306b\u53c2\u52a0\u3057\u307e\u3057\u305f',
    );
  }

  Future<void> sendTestEndedNotification({
    required String username,
    required String appName,
  }) {
    return _postMessage(
      '\u2705 $username \u304c $appName \u306e\u30c6\u30b9\u30c8\u3092\u7d42\u4e86\u3057\u307e\u3057\u305f',
    );
  }

  Future<void> _postMessage(String content) async {
    if (!kDiscordWebhookUrl.startsWith('http')) {
      return;
    }
    if (kDiscordWebhookUrl.contains('example.com')) {
      return;
    }

    HttpClient? client;
    try {
      client = HttpClient();
      final request = await client.postUrl(Uri.parse(kDiscordWebhookUrl));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'content': content}));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('Discord webhook failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Discord webhook error: $e');
    } finally {
      client?.close(force: true);
    }
  }
}
