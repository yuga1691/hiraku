import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/app_model.dart';

class MyAppCard extends StatelessWidget {
  const MyAppCard({super.key, required this.app});

  final AppModel app;

  @override
  Widget build(BuildContext context) {
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
                Text(app.message, style: const TextStyle(color: Colors.black54)),
              ],
              const SizedBox(height: 8),
              Text('残り露出枠: ${app.remainingExposure}'),
              Text('他人がOpenした累計: ${app.openedCount}'),
            ],
          ),
        ),
      ],
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
