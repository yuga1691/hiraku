import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants.dart';
import '../widgets/help_sheet.dart';

class UsageGuideScreen extends StatelessWidget {
  const UsageGuideScreen({super.key});

  static const _sections = [
    UsageHelpSection(
      title: 'STEP 1: Googleグループに参加',
      body:
          '運用チームが案内するGoogleグループに参加してください.\nこのグループに参加することで，本アプリに参加している他のユーザーのアプリをダウンロードすることができるようになります.\n（Google Playにログインできるアカウントでご参加ください.）',
      assetPath: 'assets/guide/3-1.jpg',
    ),
    UsageHelpSection(
      title: 'STEP 2: メールアドレス登録',
      body:
          '下記の「Googleグループのメールをコピー」を押してください．\nその後，Google Play Consoleを開き，上図のようにGoogleグループのメールアドレスを追加してください．\n追加することで，あなたのアプリを他のユーザーがダウンロードできるようになります．',
      assetPath: 'assets/guide/3-2.jpg',
    ),
    UsageHelpSection(
      title: 'STEP 3: 相互テスト開始',
      body:
          'アプリを登録し，テスト一覧に表示させましょう．\n10人がインストールするまでは表示されますが，11人以降はあなたが誰かのアプリをインストールしないと一覧に表示されない仕組みとなっています．\n積極的に他のユーザーのテスターとなり，あなたのアプリの表示回数を増やしましょう.\n残り表示回数はマイページから確認することができます．',
      assetPath: 'assets/guide/3-3.jpg',
    ),
    UsageHelpSection(
      title: 'STEP 4: 他のユーザーのアプリを開くにあたって',
      body:
          '他のユーザーが何回アプリを開かれたか知れるように，本アプリのマイページに存在するテスト履歴からアプリを開きましょう!\n継続的にアプリを開くことがクローズドテスト通過の鍵です！\n相互テスト継続のためにも，本アプリを介してアプリを開いていただけると幸いです！',
      assetPath: 'assets/guide/3-4.jpg',
    ),
    UsageHelpSection(
      title: 'STEP 5: 自分のアプリが過去何回開かれたか',
      body: '過去自分のアプリが何回開かれたかは，マイページから確認することができます！',
      assetPath: 'assets/guide/3-5.jpg',
    ),
    UsageHelpSection(
      title: 'APPENDIX: さらなる開発を行いたい方，フィードバックが欲しい方へ',
      body:
          'マイページから開発者が集まるDiscordコミュニティに参加することができます.\nDiscordに参加することで，アプリをリリースした際に，あなたのアプリが自動的に宣伝されたり，あなたのアプリをテストしてくれる心強い仲間を確認することができます！\n自由に話せるスペースもよういしているので，ぜひご参加ください！',
      assetPath: 'assets/guide/3-6.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('使い方')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HIRAKU の使い方', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'この画面ではアプリの基本的な使い方をご案内します．すべて読むことをお勧めします！',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._sections.map((section) => _GuideCard(section: section)),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.section});

  final UsageHelpSection section;

  bool get _isStepOne => section.title.startsWith('STEP 1');
  bool get _isStepTwo => section.title.startsWith('STEP 2');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildSectionContents(context, section.resolvedContents),
              if (_isStepOne) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _openTeamUrl,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Googleグループを開く'),
                ),
              ],
              if (_isStepTwo) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _copyTeamEmail(context),
                  icon: const Icon(Icons.copy),
                  label: const Text('Googleグループのメールをコピー'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _openPlayConsole,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Google Play Consoleを開く'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTeamUrl() async {
    final uri = Uri.parse(kTeamJoinUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyTeamEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kTeamJoinEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Googleグループのメールアドレスをコピーしました。')),
    );
  }

  Future<void> _openPlayConsole() async {
    final uri = Uri.parse('https://play.google.com/console/');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  List<Widget> _buildSectionContents(
    BuildContext context,
    List<UsageHelpContent> contents,
  ) {
    final theme = Theme.of(context);
    final widgets = <Widget>[];
    for (final content in contents) {
      if (content.isText) {
        widgets.add(
          Text(
            content.text!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        );
      } else if (content.assetPath != null && content.assetPath!.isNotEmpty) {
        widgets.add(
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              content.assetPath!,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
      widgets.add(const SizedBox(height: 12));
    }
    if (widgets.isNotEmpty) {
      widgets.removeLast();
    }
    return widgets;
  }
}
