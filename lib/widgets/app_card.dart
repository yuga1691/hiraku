import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/app_model.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.app,
    required this.onOpen,
    required this.loading,
    this.isOwnerApp = false,
  });

  final AppModel app;
  final VoidCallback onOpen;
  final bool loading;
  final bool isOwnerApp;

  @override
  Widget build(BuildContext context) {
    final isOpenDisabled = loading || isOwnerApp;
    return Card(
      elevation: isOwnerApp ? 6 : null,
      shadowColor: isOwnerApp
          ? Colors.lightBlueAccent.withOpacity(0.55)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOwnerApp
            ? BorderSide(
                color: Colors.lightBlueAccent.withOpacity(0.9),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  const SizedBox(height: 6),
                  if (app.message.isNotEmpty)
                    Text(
                      app.message,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: isOpenDisabled ? null : onOpen,
                    child: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isOwnerApp ? '自分のアプリ' : 'アプリを開く'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
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
}
