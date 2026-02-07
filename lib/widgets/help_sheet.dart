import 'package:flutter/material.dart';

class UsageHelpSection {
  const UsageHelpSection({
    required this.title,
    required this.body,
    this.assetPath,
  });

  final String title;
  final String body;
  final String? assetPath;
}

Future<void> showUsageHelpSheet(
  BuildContext context, {
  required String title,
  required List<UsageHelpSection> sections,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    builder: (context) => _HelpSheetContent(title: title, sections: sections),
  );
}

class _HelpSheetContent extends StatelessWidget {
  const _HelpSheetContent({
    required this.title,
    required this.sections,
  });

  final String title;
  final List<UsageHelpSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '知りたい項目をタップすると詳細が開きます。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return _HelpExpansionTile(section: section);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpExpansionTile extends StatefulWidget {
  const _HelpExpansionTile({required this.section});

  final UsageHelpSection section;

  @override
  State<_HelpExpansionTile> createState() => _HelpExpansionTileState();
}

class _HelpExpansionTileState extends State<_HelpExpansionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final section = widget.section;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.28),
        ),
      ),
      child: ExpansionTile(
        dense: true,
        onExpansionChanged: (value) {
          setState(() => _expanded = value);
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(section.title),
        trailing: AnimatedRotation(
          duration: const Duration(milliseconds: 200),
          turns: _expanded ? 0.25 : 0,
          child: const Icon(Icons.chevron_right),
        ),
        children: [
          if (section.assetPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                section.assetPath!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            section.body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
