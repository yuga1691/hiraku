import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_model.dart';
import '../services/firestore_service.dart';
import '../services/launcher_service.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LauncherService _launcherService = LauncherService();
  final Set<String> _loadingAppIds = {};

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('ユーザー情報を取得できません。')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: StreamBuilder<List<AppModel>>(
        stream: _firestoreService.watchAvailableApps(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final apps = snapshot.data ?? [];
          if (apps.isEmpty) {
            return const EmptyState(
              title: '表示できるアプリがありません',
              message: '相互テストの対象が増えるとここに表示されます。',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final app = apps[index];
              final loading = _loadingAppIds.contains(app.id);
              return AppCard(
                app: app,
                loading: loading,
                onOpen: () => _openApp(user.uid, app),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openApp(String userId, AppModel app) async {
    setState(() => _loadingAppIds.add(app.id));
    try {
      await _firestoreService.openOtherAppTransaction(
        currentUserId: userId,
        targetApp: app,
      );
      await _launcherService.openPlayStore(app.packageName);
    } catch (e) {
      _showSnack('処理に失敗しました: $e');
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
