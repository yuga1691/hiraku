import 'package:flutter/material.dart';

import '../widgets/help_sheet.dart';

class UsageGuideScreen extends StatelessWidget {
  const UsageGuideScreen({super.key});

  static const _sections = [
    UsageHelpSection(
      title: 'STEP 1: Googleグループに参加',
      body:
          '運用チームが案内するGoogleグループに参加してください。参加後は、メールの案内に従って設定を確認します。',
      assetPath: 'assets/guide/placeholder.png',
    ),
    UsageHelpSection(
      title: 'STEP 2: アプリを登録',
      body:
          'アプリのURLとテスト用の情報を登録します。案内メールの手順に沿って、入力と登録を完了してください。',
      assetPath: 'assets/guide/placeholder.png',
    ),
    UsageHelpSection(
      title: 'STEP 3: 14日間アプリを起動',
      body:
          'クローズドテストの期間中は、毎日アプリを起動してください。運用チームからの連絡がある場合は、指示に従って対応してください。',
      assetPath: 'assets/guide/placeholder.png',
    ),
    UsageHelpSection(
      title: '注意事項',
      body:
          '運用チームからの連絡やテスター向けの指示は必ず確認してください。テスト期間中はアプリを削除しないようにお願いします。',
      assetPath: 'assets/guide/placeholder.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('使い方'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: '使い方を開く',
            onPressed: () => showUsageHelpSheet(
              context,
              title: '使い方のガイド',
              sections: _sections,
            ),
          ),
        ],
      ),
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
                  'この画面ではアプリの基本的な使い方をご案内します。詳細は運用チームからの案内をご確認ください。',
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
            ],
          ),
        ),
      ),
    );
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
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
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
