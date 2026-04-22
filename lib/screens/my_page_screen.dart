import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_model.dart';
import '../models/testing_model.dart';
import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/launcher_service.dart';
import '../services/local_notification_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/help_sheet.dart';
import '../widgets/my_app_card.dart';
import 'onboarding_screen.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final LauncherService _launcherService = LauncherService();
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm');
  bool _requestingNotificationPermission = false;

  static const _helpSections = [
    UsageHelpSection(
      title: 'マイユーザーのアプリを開く',
      body:
          'テスト履歴から「開く」ボタンを押すと、アプリを起動できます。未インストールの場合はストアページへ遷移します。',
      assetPath: 'assets/guide/1-4.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _AccountDeletedNoticeScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '\u4f7f\u3044\u65b9\u3092\u898b\u308b',
            onPressed: () => showUsageHelpSheet(
              context,
              title: '\u30de\u30a4\u30da\u30fc\u30b8\u306e\u4f7f\u3044\u65b9',
              sections: _helpSections,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSection(user.uid),
          const SizedBox(height: 16),
          _buildMyAppSection(user.uid),
          const SizedBox(height: 16),
          _buildTestingHistory(user.uid),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String userId) {
    return StreamBuilder(
      stream: _firestoreService.watchUser(userId),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final username = (data['username'] ?? '') as String;
        final testedCount = (data['testedCountTotal'] ?? 0) as int;
        final hasInitialUserBadge =
            (data['hasInitialUserBadge'] ?? false) as bool;
        final hasOfficialBadge = (data['hasOfficialBadge'] ?? false) as bool;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u30e6\u30fc\u30b6\u30fc\u60c5\u5831',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\u30e6\u30fc\u30b6\u30fc\u540d: ${username.isEmpty ? '\u672a\u8a2d\u5b9a' : username}',
                      ),
                    ),
                    if (hasInitialUserBadge) ...[
                      const SizedBox(width: 6),
                      _PressHintBadge(
                        icon: Icons.rocket_launch,
                        color: Theme.of(context).colorScheme.primary,
                        hint: 'HIRAKUの開発に協力していただいた方です',
                      ),
                    ],
                    if (hasOfficialBadge) ...[
                      const SizedBox(width: 4),
                      _PressHintBadge(
                        icon: Icons.workspace_premium,
                        color: Theme.of(context).colorScheme.primary,
                        hint: '本アプリ開発者です',
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text('あなたがテストした回数: $testedCount'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => _editUsername(userId, username),
                  child: const Text(
                    '\u30e6\u30fc\u30b6\u30fc\u540d\u3092\u5909\u66f4',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '他の人があなたのアプリをダウンロードした際に，通知が来ます',
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _requestingNotificationPermission
                      ? null
                      : _requestNotificationPermission,
                  icon: _requestingNotificationPermission
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.notifications_active_outlined),
                  label: const Text('通知を受け取る'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDeleteAccount(userId),
                  icon: const Icon(Icons.delete_outline),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  label: const Text(
                    '\u30a2\u30ab\u30a6\u30f3\u30c8\u524a\u9664',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMyAppSection(String userId) {
    return StreamBuilder<AppModel?>(
      stream: _firestoreService.watchMyActiveApp(userId),
      builder: (context, snapshot) {
        final app = snapshot.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '\u30de\u30a4\u30a2\u30d7\u30ea',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (app == null)
                  const Text(
                    '\u767b\u9332\u4e2d\u306e\u30a2\u30d7\u30ea\u306f\u3042\u308a\u307e\u305b\u3093\u3002',
                  )
                else
                  MyAppCard(app: app),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTestingHistory(String userId) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '\u30c6\u30b9\u30c8\u5c65\u6b74',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<AppModel?>(
              stream: _firestoreService.watchMyActiveApp(userId),
              builder: (context, snapshot) {
                final myApp = snapshot.data;
                final openedByTesterAppName = myApp?.openCountByTesterAppName ?? {};
                return StreamBuilder<List<TestingModel>>(
                  stream: _firestoreService.watchTestingHistory(userId),
                  builder: (context, historySnapshot) {
                    if (historySnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                      );
                    }
                    final items = historySnapshot.data ?? [];
                    if (items.isEmpty) {
                      return const EmptyState(
                        title: '\u5c65\u6b74\u304c\u3042\u308a\u307e\u305b\u3093',
                        message:
                            '\u30c6\u30b9\u30c8\u3057\u305f\u30a2\u30d7\u30ea\u304c\u3053\u3053\u306b\u8868\u793a\u3055\u308c\u307e\u3059\u3002',
                      );
                    }
                    return Column(
                      children: items
                          .map(
                            (item) {
                              final openCountByOtherToMe =
                                  openedByTesterAppName[item.name] ?? 0;
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Wrap(
                                  spacing: 4,
                                  runSpacing: 2,
                                  children: [
                                    Text(item.name),
                                    if (item.isEndedByDeveloper)
                                      Text(
                                        '（テスト終了）',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.error,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Text(
                                  'あなた→相手: ${item.openCountByMe}回 / 相手→あなた: ${openCountByOtherToMe}回'
                                  '${item.lastOpenedAt == null ? '' : '\n最終: ${_dateFormat.format(item.lastOpenedAt!)}'}',
                                ),
                                onTap: () => _openTestedApp(item),
                                trailing: FilledButton.tonal(
                                  onPressed: () => _openTestedApp(item),
                                  child: const Text('\u958b\u304f'),
                                ),
                              );
                            },
                          )
                          .toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTestedApp(TestingModel item) async {
    if (item.playUrl.isEmpty && item.packageName.isEmpty) {
      _showSnack(
        'URL\u304c\u8a2d\u5b9a\u3055\u308c\u3066\u3044\u307e\u305b\u3093\u3002',
      );
      return;
    }
    try {
      await _firestoreService.openTestedAppTransaction(
        currentUserId: FirebaseAuth.instance.currentUser!.uid,
        history: item,
      );
      final opened = item.packageName.isEmpty
          ? await _launcherService.openWebUrl(
              packageName: item.packageName,
              playUrl: item.playUrl,
            )
          : await _launcherService.openInstalledOrStore(
              packageName: item.packageName,
              playUrl: item.playUrl,
            );
      if (!opened) {
        _showSnack(
          '\u30b9\u30c8\u30a2\u3092\u958b\u3051\u307e\u305b\u3093\u3067\u3057\u305f\u3002URL\u3092\u78ba\u8a8d\u3057\u3066\u304f\u3060\u3055\u3044\u3002',
        );
      }
    } catch (e) {
      _showSnack('\u8d77\u52d5\u306b\u5931\u6557\u3057\u307e\u3057\u305f: $e');
    }
  }

  Future<void> _editUsername(String userId, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\u30e6\u30fc\u30b6\u30fc\u540d\u3092\u5909\u66f4'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '\u30e6\u30fc\u30b6\u30fc\u540d',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\u30ad\u30e3\u30f3\u30bb\u30eb'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('\u4fdd\u5b58'),
          ),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    await _firestoreService.updateUsername(userId, result);
  }

  Future<void> _confirmDeleteAccount(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\u30a2\u30ab\u30a6\u30f3\u30c8\u524a\u9664'),
        content: const Text(
          '\u3053\u306e\u64cd\u4f5c\u306f\u53d6\u308a\u6d88\u305b\u307e\u305b\u3093\u3002\u672c\u5f53\u306b\u524a\u9664\u3057\u307e\u3059\u304b\uff1f',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('\u30ad\u30e3\u30f3\u30bb\u30eb'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('\u524a\u9664\u3059\u308b'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final inputController = TextEditingController();
    final confirmText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('\u6700\u7d42\u78ba\u8a8d'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '\u524a\u9664\u3059\u308b\u306b\u306f\u300c\u524a\u9664\u300d\u3068\u5165\u529b\u3057\u3066\u304f\u3060\u3055\u3044\u3002',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: inputController,
              decoration: const InputDecoration(
                labelText: '\u78ba\u8a8d\u5165\u529b',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('\u30ad\u30e3\u30f3\u30bb\u30eb'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, inputController.text.trim()),
            child: const Text('\u78ba\u5b9a'),
          ),
        ],
      ),
    );

    if (confirmText != '\u524a\u9664') {
      _showSnack(
        '\u300c\u524a\u9664\u300d\u3068\u5165\u529b\u3057\u305f\u5834\u5408\u306e\u307f\u524a\u9664\u3067\u304d\u307e\u3059\u3002',
      );
      return;
    }

    try {
      await _firestoreService.deleteUserData(userId);
      await FirebaseAuth.instance.currentUser?.delete();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const _AccountDeletedNoticeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showSnack(
          '\u518d\u30ed\u30b0\u30a4\u30f3\u5f8c\u306b\u518d\u5ea6\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002',
        );
      } else {
        _showSnack(
          '\u30a2\u30ab\u30a6\u30f3\u30c8\u524a\u9664\u306b\u5931\u6557\u3057\u307e\u3057\u305f: ${e.code}',
        );
      }
    } catch (e) {
      _showSnack(
        '\u30a2\u30ab\u30a6\u30f3\u30c8\u524a\u9664\u306b\u5931\u6557\u3057\u307e\u3057\u305f: $e',
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_requestingNotificationPermission) return;
    setState(() => _requestingNotificationPermission = true);
    try {
      final granted = await LocalNotificationService.instance
          .requestPermission();
      if (!mounted) return;
      if (granted) {
        await _analyticsService.logNotificationPermissionGranted();
        _showSnack('通知を許可しました。');
      } else {
        _showSnack('通知が許可されませんでした。端末設定から許可してください。');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('通知権限の確認に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() => _requestingNotificationPermission = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AccountDeletedNoticeScreen extends StatelessWidget {
  const _AccountDeletedNoticeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, size: 56),
              const SizedBox(height: 16),
              const Text(
                '\u30a2\u30ab\u30a6\u30f3\u30c8\u304c\u524a\u9664\u3055\u308c\u307e\u3057\u305f',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '\u3053\u306e\u64cd\u4f5c\u306f\u53d6\u308a\u6d88\u305b\u307e\u305b\u3093\u3002',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    (route) => false,
                  );
                },
                child: const Text('\u521d\u671f\u753b\u9762\u306b\u623b\u308b'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _PressHintBadge extends StatefulWidget {
  const _PressHintBadge({
    required this.icon,
    required this.color,
    required this.hint,
  });

  final IconData icon;
  final Color color;
  final String hint;

  @override
  State<_PressHintBadge> createState() => _PressHintBadgeState();
}

class _PressHintBadgeState extends State<_PressHintBadge> {
  bool _showHint = false;
  Timer? _hideTimer;

  void _setHintVisible(bool visible) {
    _hideTimer?.cancel();
    if (_showHint == visible) return;
    setState(() => _showHint = visible);
  }

  void _scheduleHideHint() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _setHintVisible(false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) => _setHintVisible(true),
              onTapUp: (_) => _scheduleHideHint(),
              onTapCancel: _scheduleHideHint,
              child: Icon(
                widget.icon,
                size: 16,
                color: widget.color,
              ),
            ),
          ),
          if (_showHint)
            Positioned(
              bottom: 22,
              right: -8,
              child: Material(
                color: Colors.black.withOpacity(0.88),
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      widget.hint,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
