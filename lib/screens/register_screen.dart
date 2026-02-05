import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_model.dart';
import '../services/firestore_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/my_app_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _iconBase64;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _messageController.dispose();
    super.dispose();
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
      appBar: AppBar(title: const Text('登録')),
      body: StreamBuilder<AppModel?>(
        stream: _firestoreService.watchMyActiveApp(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final myApp = snapshot.data;
          if (myApp != null) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '現在のアプリ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                MyAppCard(app: myApp),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _endApp(myApp.id),
                  child: const Text('テストを終了'),
                ),
                const SizedBox(height: 12),
                const Text(
                  '同時に登録できるアプリは1つだけです。別のアプリを登録するには、先にテストを終了してください。',
                ),
              ],
            );
          }
          return _buildRegisterForm(user.uid);
        },
      ),
    );
  }

  Widget _buildRegisterForm(String userId) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'アプリ登録',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'アプリ名（タイトル）',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'Google Play URL',
            hintText: 'https://play.google.com/store/apps/details?id=...',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageController,
          decoration: const InputDecoration(
            labelText: '一言コメント（任意）',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.tonal(
              onPressed: _pickIcon,
              child: const Text('アイコンを選択'),
            ),
            const SizedBox(width: 12),
            if (_iconBase64 != null) const Text('選択済み'),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : () => _register(userId),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('登録する'),
        ),
        const SizedBox(height: 16),
        const EmptyState(
          title: '注意',
          message:
              '登録できるアプリは常に1つだけです。テスト終了後に次のアプリを登録してください。',
        ),
      ],
    );
  }

  Future<void> _pickIcon() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await File(picked.path).readAsBytes();
    setState(() => _iconBase64 = base64Encode(bytes));
  }

  Future<void> _register(String userId) async {
    final name = _nameController.text.trim();
    final playUrl = _urlController.text.trim();
    final message = _messageController.text.trim();
    if (name.isEmpty || playUrl.isEmpty) {
      _showSnack('必須項目を入力してください。');
      return;
    }
    final packageName = _extractPackageName(playUrl);
    if (packageName == null) {
      _showSnack('Google Play URLからパッケージ名を取得できません。');
      return;
    }
    setState(() => _saving = true);
    try {
      await _firestoreService.registerApp(
        userId: userId,
        name: name,
        playUrl: playUrl,
        packageName: packageName,
        message: message,
        iconBase64: _iconBase64,
      );
      _nameController.clear();
      _urlController.clear();
      _messageController.clear();
      setState(() => _iconBase64 = null);
      _showSnack('登録しました。');
    } catch (e) {
      _showSnack('登録に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _extractPackageName(String playUrl) {
    try {
      final uri = Uri.parse(playUrl);
      final id = uri.queryParameters['id'];
      if (id == null || id.isEmpty) {
        return null;
      }
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<void> _endApp(String appId) async {
    try {
      await _firestoreService.endMyApp(appId);
      _showSnack('テストを終了しました。');
    } catch (e) {
      _showSnack('終了に失敗しました: $e');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
