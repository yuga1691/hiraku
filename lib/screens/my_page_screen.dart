import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
        title: _buildAppBarTitle(user.uid),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '使い方を見る',
            onPressed: () => showUsageHelpSheet(
              context,
              title: 'マイページの使い方',
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

  Widget _buildAppBarTitle(String userId) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('マイページ'),
        const SizedBox(width: 6),
        _buildAdminNotificationButton(userId),
      ],
    );
  }

  Widget _buildAdminNotificationButton(String userId) {
    return StreamBuilder<int>(
      stream: _firestoreService.watchAdminNotificationUnreadCount(userId),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Tooltip(
          message: '運営からの通知ボックス',
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => _openAdminNotificationBox(userId),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAdminNotificationBox(String userId) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '運営からの通知ボックス',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestoreService.watchAdminNotifications(userId),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('通知の取得に失敗しました。'),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const EmptyState(
                            title: '通知はまだありません',
                            message: '運営からのお知らせがここに表示されます。',
                          );
                        }
                        return ListView.separated(
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final data = doc.data();
                            final title = (data['title'] ?? 'お知らせ') as String;
                            final body = (data['body'] ?? '') as String;
                            final isRead = (data['isRead'] ?? false) as bool;
                            final createdAtRaw = data['createdAt'];
                            final createdAt = createdAtRaw is Timestamp
                                ? createdAtRaw.toDate()
                                : null;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isRead
                                    ? Icons.mark_email_read_outlined
                                    : Icons.mark_email_unread_outlined,
                                color: isRead
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6)
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                title,
                                style: TextStyle(
                                  fontWeight:
                                      isRead ? FontWeight.w500 : FontWeight.w700,
                                ),
                              ),
                              subtitle: createdAt == null
                                  ? null
                                  : Text(_dateFormat.format(createdAt)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await _openAdminNotificationDetail(
                                  title: title,
                                  body: body,
                                  createdAt: createdAt,
                                );
                                if (!isRead) {
                                  await _firestoreService.markAdminNotificationAsRead(
                                    userId: userId,
                                    notificationId: doc.id,
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAdminNotificationDetail({
    required String title,
    required String body,
    required DateTime? createdAt,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title.trim().isEmpty ? 'お知らせ' : title.trim()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (createdAt != null)
                Text(
                  _dateFormat.format(createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (createdAt != null) const SizedBox(height: 8),
              Text(
                body.trim().isEmpty ? '本文はありません。' : body.trim(),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
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
                  'ユーザー情報',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ユーザー名: ${username.isEmpty ? '未設定' : username}',
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
                    'ユーザー名を変更',
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
                    'アカウント削除',
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
                  'マイアプリ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (app == null)
                  const Text(
                    '登録中のアプリはありません。',
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
              'テスト履歴',
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
                        title: '履歴がありません',
                        message:
                            'テストしたアプリがここに表示されます。',
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
                                  child: const Text('開く'),
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
        'URLが設定されていません。',
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
          'ストアを開けませんでした。URLを確認してください。',
        );
      }
    } catch (e) {
      _showSnack('起動に失敗しました: $e');
    }
  }

  Future<void> _editUsername(String userId, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ユーザー名を変更'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'ユーザー名',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('保存'),
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
        title: const Text('アカウント削除'),
        content: const Text(
          'この操作は取り消せません。本当に削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除する'),
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
        title: const Text('最終確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '削除するには「削除」と入力してください。',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: inputController,
              decoration: const InputDecoration(
                labelText: '確認入力',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, inputController.text.trim()),
            child: const Text('確定'),
          ),
        ],
      ),
    );

    if (confirmText != '削除') {
      _showSnack(
        '「削除」と入力した場合のみ削除できます。',
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
          '再ログイン後に再度お試しください。',
        );
      } else {
        _showSnack(
          'アカウント削除に失敗しました: ${e.code}',
        );
      }
    } catch (e) {
      _showSnack(
        'アカウント削除に失敗しました: $e',
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
                'アカウントが削除されました',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'この操作は取り消せません。',
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
                child: const Text('初期画面に戻る'),
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
