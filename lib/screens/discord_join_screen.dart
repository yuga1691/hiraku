import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../constants.dart';
import '../services/discord_webhook_service.dart';
import '../services/firestore_service.dart';
import '../services/launcher_service.dart';

class DiscordJoinScreen extends StatefulWidget {
  const DiscordJoinScreen({super.key});

  @override
  State<DiscordJoinScreen> createState() => _DiscordJoinScreenState();
}

class _DiscordJoinScreenState extends State<DiscordJoinScreen> {
  final LauncherService _launcherService = LauncherService();
  final FirestoreService _firestoreService = FirestoreService();
  final DiscordWebhookService _discordWebhookService = DiscordWebhookService();
  final _DiscordJoinLifecycleObserver _lifecycleObserver =
      _DiscordJoinLifecycleObserver();

  bool _waitingConfirmation = false;
  bool _dialogShowing = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver.onResumed = _onResumed;
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    _lifecycleObserver.onResumed = null;
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  void _onResumed() {
    if (!_waitingConfirmation || _dialogShowing) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    Future.microtask(_showJoinConfirmationDialog);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discord\u53c2\u52a0')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discord\u306b\u53c2\u52a0\u3059\u308b',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '\u30dc\u30bf\u30f3\u3092\u62bc\u3059\u3068Discord\u30a2\u30d7\u30ea\u307e\u305f\u306f\u30d6\u30e9\u30a6\u30b6\u304c\u958b\u304d\u307e\u3059\u3002',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDiscordInviteUrl,
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _processing ? null : _openDiscordInvite,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text(
                      'Discord\u306b\u53c2\u52a0\u3059\u308b\uff08\u62db\u5f85\u30ea\u30f3\u30af\uff09',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDiscordInvite() async {
    final opened = await _launcherService.openWebUrl(
      packageName: '',
      playUrl: kDiscordInviteUrl,
    );
    if (!opened) {
      _showSnack(
        'Discord\u62db\u5f85\u30ea\u30f3\u30af\u3092\u958b\u3051\u307e\u305b\u3093\u3067\u3057\u305f\u3002',
      );
      return;
    }
    _waitingConfirmation = true;
  }

  Future<void> _showJoinConfirmationDialog() async {
    if (!mounted || _dialogShowing) return;
    _dialogShowing = true;
    final joined = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('\u78ba\u8a8d'),
        content: const Text(
          'Discord\u306b\u53c2\u52a0\u3057\u307e\u3057\u305f\u304b\uff1f',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('\u3044\u3044\u3048'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('\u306f\u3044'),
          ),
        ],
      ),
    );
    _dialogShowing = false;
    _waitingConfirmation = false;

    if (joined == true) {
      await _confirmJoined();
    }
  }

  Future<void> _confirmJoined() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnack(
          '\u30e6\u30fc\u30b6\u30fc\u60c5\u5831\u3092\u53d6\u5f97\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002',
        );
        return;
      }

      final wasOptedIn = await _discordWebhookService.isDiscordOptIn();
      await _discordWebhookService.setDiscordOptIn(true);

      if (!wasOptedIn) {
        final username = await _firestoreService.fetchUsername(user.uid);
        await _discordWebhookService.sendDiscordJoinNotification(
          username: username,
        );

        final sentRegisteredApp =
            await _discordWebhookService.hasSentRegisteredAppOnDiscordJoin();
        final myApp = await _firestoreService.fetchMyActiveAppOnce(user.uid);
        if (!sentRegisteredApp && myApp != null) {
          await _discordWebhookService.sendRegisteredAppOnDiscordJoinNotification(
            username: username,
            appName: myApp.name,
            appDescription: myApp.message,
            playUrl: myApp.playUrl,
          );
          await _discordWebhookService.markRegisteredAppOnDiscordJoinSent();
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      _showSnack(
        'Discord\u53c2\u52a0\u306e\u53cd\u6620\u306b\u5931\u6557\u3057\u307e\u3057\u305f: $e',
      );
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _DiscordJoinLifecycleObserver with WidgetsBindingObserver {
  void Function()? onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed?.call();
    }
  }
}
