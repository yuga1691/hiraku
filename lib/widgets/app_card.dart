import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/app_model.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.app,
    required this.onOpen,
    required this.loading,
  });

  final AppModel app;
  final VoidCallback onOpen;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                      style: const TextStyle(color: Colors.black54),
                    ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: loading ? null : onOpen,
                    child: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Open App'),
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
