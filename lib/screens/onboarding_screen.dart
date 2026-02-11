import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../services/firestore_service.dart';
import '../services/onboarding_service.dart';
import '../widgets/cyber_background.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _totalSteps = 4;

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
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.headlineMedium?.copyWith(
      color: theme.colorScheme.onBackground,
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CyberBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.4),
                        ),
                      ),
                      child: Text(
                        'HIRAKU',
                        style: theme.textTheme.labelLarge?.copyWith(
                          letterSpacing: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _StepChip(label: 'STEP ${_pageIndex + 1} / $_totalSteps'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('ONBOARDING', style: titleStyle),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: (_pageIndex + 1) / _totalSteps,
                    backgroundColor: theme.colorScheme.surface.withOpacity(0.6),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildOverviewPage(context),
                    _buildTeamJoinPage(context),
                    _buildPlayConsolePage(context),
                    _buildUsernamePage(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewPage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('クローズドテスト参加について', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '本アプリのテスト参加には、Google Play の公式「クローズドテスト機能」を利用しています。'
              '\nテスター管理のために Googleグループ を使用します。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '仕組み\n'
              '1. テスターとして参加する場合\n'
              'Googleグループへ参加すると、Playストアからテスト版をインストールできます。\n'
              '2. 自分のアプリをテストしてもらう場合\n'
              'Play Console のクローズドテスト設定に、指定の Googleグループメールアドレスを登録します。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '安全性\n'
              '・使用するのはメールアドレスのみ\n'
              '・個人情報の取得や端末アクセスは行いません\n'
              '・すべて Google Play 公式の仕組み内で動作します',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                TextButton(onPressed: () => _goToPage(_totalSteps - 1), child: const Text('スキップ')),
                const Spacer(),
                FilledButton(onPressed: _nextPage, child: const Text('次へ')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamJoinPage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('テストチームに参加', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'このページでは Googleグループの参加リンクのみを表示します。'
              '\nGoogleグループへ参加後、次へ進んでください。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: SelectableText(
                kTeamJoinUrl,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openTeamUrl,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Googleグループを開く'),
            ),
            const Spacer(),
            Row(
              children: [
                TextButton(
                  onPressed: _pageIndex == 0 ? null : _prevPage,
                  child: const Text('戻る'),
                ),
                const Spacer(),
                FilledButton(onPressed: _nextPage, child: const Text('次へ')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayConsolePage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Google Play Console 登録', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '自分のアプリをテストしてもらう場合は、下記メールアドレスをコピーして '
              'Google Play Console のクローズドテスト設定へ登録してください。'
              '\nこのアプリ内への入力は不要です。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: SelectableText(
                kTeamJoinEmail,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyTeamEmail,
              icon: const Icon(Icons.copy),
              label: const Text('メールアドレスをコピー'),
            ),
            const Spacer(),
            Row(
              children: [
                TextButton(
                  onPressed: _pageIndex == 0 ? null : _prevPage,
                  child: const Text('戻る'),
                ),
                const Spacer(),
                FilledButton(onPressed: _nextPage, child: const Text('次へ')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsernamePage(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ユーザー名を設定', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'この名前はアプリ内で表示されます。後から変更できます。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'ユーザー名',
                hintText: '例: zero_g',
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
                      : const Text('完了して始める'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _nextPage() {
    if (_pageIndex >= _totalSteps - 1) {
      return;
    }
    _goToPage(_pageIndex + 1);
  }

  void _prevPage() {
    if (_pageIndex <= 0) {
      return;
    }
    _goToPage(_pageIndex - 1);
  }

  void _goToPage(int nextPage) {
    setState(() => _pageIndex = nextPage);
    _pageController.animateToPage(
      nextPage,
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
        throw Exception('ユーザーが認証されていません。');
      }
      await _firestoreService.ensureUserDoc(user.uid);
      await _firestoreService.updateUsername(user.uid, username);
      await _onboardingService.markCompleted();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
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

  Future<void> _copyTeamEmail() async {
    await Clipboard.setData(const ClipboardData(text: kTeamJoinEmail));
    if (!mounted) return;
    _showSnack('Googleグループのメールアドレスをコピーしました。');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.45)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
