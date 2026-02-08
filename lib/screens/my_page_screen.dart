import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/app_model.dart';
import '../models/testing_model.dart';
import '../services/firestore_service.dart';
import '../services/launcher_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/help_sheet.dart';
import '../widgets/my_app_card.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LauncherService _launcherService = LauncherService();
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm');

  static const _helpSections = [
    UsageHelpSection(
      title: 'プロフィールを更新',
      body: '仮の説明文です。ユーザー名を変更できます。',
      assetPath: 'assets/guide/placeholder.png',
    ),
    UsageHelpSection(
      title: 'テスト履歴を確認',
      body: '仮の説明文です。開いたアプリの履歴が表示されます。',
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
        title: const Text('マイページ'),
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
          _buildTeamSection(),
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
                Text('ユーザー名: ${username.isEmpty ? '未設定' : username}'),
                const SizedBox(height: 4),
                Text('テスト回数: $testedCount'),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => _editUsername(userId, username),
                  child: const Text('ユーザー名を変更'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Team',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('テストに参加するにはチーム参加が必要です。'),
            const SizedBox(height: 8),
            Text(
              kTeamJoinUrl,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Text(
              kTeamJoinEmail,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _copyTeamEmail,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Email'),
                ),
                OutlinedButton.icon(
                  onPressed: _openTeamEmail,
                  icon: const Icon(Icons.email),
                  label: const Text('Send Email'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _openTeamUrl,
              child: const Text('リンクを開く'),
            ),
          ],
        ),
      ),
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
                  const Text('登録中のアプリはありません。')
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
            StreamBuilder<List<TestingModel>>(
              stream: _firestoreService.watchTestingHistory(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const EmptyState(
                    title: '履歴がありません',
                    message: 'テストしたアプリがここに表示されます。',
                  );
                }
                return Column(
                  children: items
                      .map(
                        (item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item.name),
                          subtitle: Text(
                            'Open回数: ${item.openCountByMe}'
                            '${item.lastOpenedAt == null ? '' : ' / 最終: ${_dateFormat.format(item.lastOpenedAt!)}'}',
                          ),
                          onTap: () => _openTestedApp(item),
                          trailing: FilledButton.tonal(
                            onPressed: () => _openTestedApp(item),
                            child: const Text('開く'),
                          ),
                        ),
                      )
                      .toList(),
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
      _showSnack('URLが設定されていません。');
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
        _showSnack('ストアを開けませんでした。URLを確認してください。');
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
          decoration: const InputDecoration(labelText: 'ユーザー名'),
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

  Future<void> _openTeamUrl() async {
    final uri = Uri.parse(kTeamJoinUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openTeamEmail() async {
    final uri = Uri(scheme: 'mailto', path: kTeamJoinEmail);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyTeamEmail() async {
    await Clipboard.setData(const ClipboardData(text: kTeamJoinEmail));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied Google Group email.')),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
