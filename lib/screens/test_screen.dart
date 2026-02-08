import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_model.dart';
import '../services/firestore_service.dart';
import '../services/launcher_service.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/help_sheet.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LauncherService _launcherService = LauncherService();
  final Set<String> _loadingAppIds = {};

  static const _helpSections = [
    UsageHelpSection(
      title: 'テストするアプリを選ぶ',
      body: '仮の説明文です。一覧からアプリを選んで詳細を確認します。',
      assetPath: 'assets/guide/placeholder.png',
    ),
    UsageHelpSection(
      title: 'アプリを開く',
      body: '仮の説明文です。開くボタンを押すとストアが開きます。',
      assetPath: 'assets/guide/placeholder.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('ユーザー認証に失敗しました。')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('テスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '使い方を見る',
            onPressed: () => showUsageHelpSheet(
              context,
              title: 'テストの使い方',
              sections: _helpSections,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppModel>>(
        stream: _firestoreService.watchAvailableApps(),
        builder: (context, appsSnapshot) {
          return StreamBuilder(
            stream: _firestoreService.watchTestingHistory(user.uid),
            builder: (context, historySnapshot) {
              if (appsSnapshot.connectionState == ConnectionState.waiting ||
                  historySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (appsSnapshot.hasError) {
                return EmptyState(
                  title: 'テスト一覧を読み込めません',
                  message: '読み込み中にエラーが発生しました: ${appsSnapshot.error}',
                );
              }
              if (historySnapshot.hasError) {
                return EmptyState(
                  title: 'テスト履歴を読み込めません',
                  message: '読み込み中にエラーが発生しました: ${historySnapshot.error}',
                );
              }
              final apps = appsSnapshot.data ?? [];
              final testedIds = (historySnapshot.data ?? [])
                  .map((item) => item.appId)
                  .toSet();
              final visibleApps = apps
                  .where((app) => app.ownerUserId != user.uid)
                  .where((app) => !testedIds.contains(app.id))
                  .toList();
              if (visibleApps.isEmpty) {
                return const EmptyState(
                  title: 'テストできるアプリがありません',
                  message: '他のユーザーが登録したアプリが表示されます。',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: visibleApps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final app = visibleApps[index];
                  final loading = _loadingAppIds.contains(app.id);
                  return AppCard(
                    app: app,
                    loading: loading,
                    onOpen: () => _showAppDetails(user.uid, app),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAppDetails(String userId, AppModel app) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(app.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('URL'),
                const SizedBox(height: 4),
                SelectableText(app.playUrl),
                const SizedBox(height: 12),
                const Text('コメント'),
                const SizedBox(height: 4),
                SelectableText(app.message.isEmpty ? '（コメントなし）' : app.message),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
            TextButton(
              onPressed: () async {
                final opened = await _launcherService.openWebUrl(
                  packageName: app.packageName,
                  playUrl: app.playUrl,
                );
                if (!opened && mounted) {
                  _showSnack('URLを開けませんでした。');
                }
              },
              child: const Text('URLを開く'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: app.playUrl));
                if (mounted) {
                  _showSnack('URLをコピーしました。');
                }
              },
              child: const Text('URLをコピー'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openApp(userId, app);
              },
              child: const Text('ストアを開く'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openApp(String userId, AppModel app) async {
    setState(() => _loadingAppIds.add(app.id));
    try {
      await _firestoreService.openOtherAppTransaction(
        currentUserId: userId,
        targetApp: app,
      );
      final opened = await _launcherService.openPlayStore(
        packageName: app.packageName,
        playUrl: app.playUrl,
      );
      if (!opened) {
        _showSnack('ストアを開けませんでした。URLを確認してください。');
      }
    } catch (e) {
      _showSnack('起動に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingAppIds.remove(app.id));
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
