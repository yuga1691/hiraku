import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  String? _pendingUserId;
  AppModel? _pendingInstallApp;
  bool _isInstallConfirmDialogShowing = false;

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
  void initState() {
    super.initState();
    _lifecycleObserver.onResumed = _onAppResumed;
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    _lifecycleObserver.onResumed = null;
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  final _TestLifecycleObserver _lifecycleObserver = _TestLifecycleObserver();

  void _onAppResumed() {
    if (_pendingInstallApp == null || _isInstallConfirmDialogShowing) return;
    if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
    Future.microtask(_showInstallConfirmationDialog);
  }

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
      _pendingUserId = userId;
      _pendingInstallApp = app;
      final opened = await _launcherService.openPlayStore(
        packageName: app.packageName,
        playUrl: app.playUrl,
      );
      if (!opened) {
        _pendingUserId = null;
        _pendingInstallApp = null;
        _showSnack('ストアを開けませんでした。URLを確認してください。');
      }
    } catch (e) {
      _pendingUserId = null;
      _pendingInstallApp = null;
      _showSnack('起動に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingAppIds.remove(app.id));
      }
    }
  }

  Future<void> _showInstallConfirmationDialog() async {
    final userId = _pendingUserId;
    final app = _pendingInstallApp;
    if (!mounted || userId == null || app == null || _isInstallConfirmDialogShowing) {
      return;
    }

    _isInstallConfirmDialogShowing = true;
    final installed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: Text('${app.name} をインストールしましたか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('いいえ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('はい'),
          ),
        ],
      ),
    );
    _isInstallConfirmDialogShowing = false;

    _pendingUserId = null;
    _pendingInstallApp = null;

    if (installed != true) return;

    try {
      await _firestoreService.confirmOtherAppInstallTransaction(
        currentUserId: userId,
        targetApp: app,
      );
      if (!mounted) return;
      _showSnack('テスト履歴に追加しました。');
    } catch (e) {
      if (!mounted) return;
      _showSnack('履歴追加に失敗しました: $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _TestLifecycleObserver with WidgetsBindingObserver {
  _TestLifecycleObserver();

  void Function()? onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed?.call();
    }
  }
}
