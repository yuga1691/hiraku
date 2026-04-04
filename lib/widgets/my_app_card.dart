import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_model.dart';

class MyAppCard extends StatefulWidget {
  const MyAppCard({super.key, required this.app});

  final AppModel app;

  @override
  State<MyAppCard> createState() => _MyAppCardState();
}

class _MyAppCardState extends State<MyAppCard> {
  final DateFormat _dateLabelFormat = DateFormat('yyyy年M月d日');

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final groupedLogs = _groupLogsByDate(app.recentOpenLogs);
    final recentDateEntries = groupedLogs.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIcon(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (app.message.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  app.message,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text('テスト一覧表示回数 残り: ${app.remainingExposure}'),
              Text('開かれた回数（累計）: ${app.openedCount}'),
              const SizedBox(height: 8),
              const Text('直近1週間の開かれた記録'),
              if (recentDateEntries.isEmpty) ...[
                const SizedBox(height: 4),
                const Text('まだ記録はありません'),
              ] else ...[
                const SizedBox(height: 4),
                ...recentDateEntries.map(
                  (entry) => _buildDateTile(
                    context,
                    entry.key,
                    entry.value,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTile(
    BuildContext context,
    String dateKey,
    Map<String, int> testerCounts,
  ) {
    final items = testerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalCount = items.fold<int>(0, (sum, entry) => sum + entry.value);
    final date = DateTime.tryParse(dateKey);
    final title = date == null
        ? dateKey
        : _dateLabelFormat.format(DateTime(date.year, date.month, date.day));

    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.35),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(title),
        subtitle: Text('合計 $totalCount回'),
        children: items
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    const SizedBox(width: 12),
                    Text('${entry.value}回'),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildIcon() {
    final app = widget.app;
    if (app.iconBase64 == null || app.iconBase64!.isEmpty) {
      return const CircleAvatar(
        radius: 28,
        child: Icon(Icons.apps),
      );
    }
    final bytes = base64Decode(app.iconBase64!);
    return CircleAvatar(
      radius: 28,
      backgroundImage: MemoryImage(bytes),
    );
  }

  Map<String, Map<String, int>> _groupLogsByDate(List<AppOpenLogEntry> logs) {
    final grouped = <String, Map<String, int>>{};
    for (final log in logs) {
      final perDate = grouped.putIfAbsent(log.dateKey, () => <String, int>{});
      perDate.update(log.testerAppName, (count) => count + 1, ifAbsent: () => 1);
    }
    return grouped;
  }
}
