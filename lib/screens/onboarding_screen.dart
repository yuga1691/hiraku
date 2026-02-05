import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../services/firestore_service.dart';
import '../services/onboarding_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _usernameController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final OnboardingService _onboardingService = OnboardingService();

  int _pageIndex = 0;
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('hiraku はじめに'),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_pageIndex + 1) / 2),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTeamPage(context),
                _buildUsernamePage(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Google Team 参加のご案内',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            '参加すると、テスト対象アプリのインストールが可能になります。',
          ),
          const SizedBox(height: 16),
          Text(
            kTeamJoinUrl,
            style: const TextStyle(color: Colors.blueGrey),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _openTeamUrl,
            child: const Text('外部ブラウザで開く'),
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(
                onPressed: _nextPage,
                child: const Text('スキップ'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _nextPage,
                child: const Text('次へ'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsernamePage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ユーザー名を設定してください',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text('この名前はアプリ内で表示されます。'),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'ユーザー名',
              border: OutlineInputBorder(),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              TextButton(
                onPressed: _pageIndex == 0 ? null : _prevPage,
                child: const Text('戻る'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _complete,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存して開始'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    setState(() => _pageIndex = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _prevPage() {
    setState(() => _pageIndex = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _complete() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showSnack('ユーザー名を入力してください。');
      return;
    }
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('ユーザーが取得できません。');
      }
      await _firestoreService.ensureUserDoc(user.uid);
      await _firestoreService.updateUsername(user.uid, username);
      await _onboardingService.markCompleted();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      _showSnack('保存に失敗しました: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openTeamUrl() async {
    final uri = Uri.parse(kTeamJoinUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
