import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../models/app_model.dart';
import '../models/testing_model.dart';
import '../services/firestore_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/my_app_card.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('ユーザー情報を取得できません。')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Page')),
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
                Text('相互テスト回数: $testedCount'),
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
            const Text('参加すると、テスト対象アプリのインストールが可能になります。'),
            const SizedBox(height: 8),
            Text(
              kTeamJoinUrl,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _openTeamUrl,
              child: const Text('外部ブラウザで開く'),
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
                  'My App',
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
              'Testing履歴',
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
                    message: '他人のアプリをOpenするとここに記録されます。',
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
}
