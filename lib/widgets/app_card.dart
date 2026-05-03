import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/app_model.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.app,
    required this.onOpen,
    required this.loading,
    required this.ownerUsername,
    required this.hasInitialUserBadge,
    required this.hasOfficialBadge,
    this.isOwnerApp = false,
  });

  final AppModel app;
  final VoidCallback onOpen;
  final bool loading;
  final String ownerUsername;
  final bool hasInitialUserBadge;
  final bool hasOfficialBadge;
  final bool isOwnerApp;

  @override
  Widget build(BuildContext context) {
    final isOpenDisabled = loading || isOwnerApp;
    return Card(
      elevation: isOwnerApp ? 6 : null,
      shadowColor: isOwnerApp ? Colors.lightBlueAccent.withOpacity(0.55) : null,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ownerUsername,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildBadgeArea(context),
                    ],
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
                        : Text(isOwnerApp ? '自分のアプリ' : '詳細を見る'),
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
      return const CircleAvatar(radius: 28, child: Icon(Icons.apps));
    }
    final bytes = base64Decode(app.iconBase64!);
    return CircleAvatar(radius: 28, backgroundImage: MemoryImage(bytes));
  }

  Widget _buildBadgeArea(BuildContext context) {
    final badgeColor = Theme.of(context).colorScheme.primary;
    final badges = <Widget>[
      if (hasInitialUserBadge)
        _PressHintIcon(
          icon: Icons.rocket_launch,
          color: badgeColor,
          hint: 'HIRAKUの開発に協力していただいた方です',
        ),
      if (hasOfficialBadge)
        _PressHintIcon(
          icon: Icons.workspace_premium,
          color: badgeColor,
          hint: '本アプリ開発者です',
        ),
    ];
    if (badges.isEmpty) {
      return const SizedBox(width: 16, height: 16);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < badges.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          badges[i],
        ],
      ],
    );
  }
}

class _PressHintIcon extends StatefulWidget {
  const _PressHintIcon({
    required this.icon,
    required this.color,
    required this.hint,
  });

  final IconData icon;
  final Color color;
  final String hint;

  @override
  State<_PressHintIcon> createState() => _PressHintIconState();
}

class _PressHintIconState extends State<_PressHintIcon> {
  bool _showHint = false;
  Timer? _hideTimer;

  void _setHintVisible(bool visible) {
    _hideTimer?.cancel();
    if (_showHint == visible) return;
    setState(() => _showHint = visible);
  }

  void _scheduleHideHint() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _setHintVisible(false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) => _setHintVisible(true),
              onTapUp: (_) => _scheduleHideHint(),
              onTapCancel: _scheduleHideHint,
              child: Icon(widget.icon, size: 16, color: widget.color),
            ),
          ),
          if (_showHint)
            Positioned(
              bottom: 22,
              right: -8,
              child: Material(
                color: Colors.black.withOpacity(0.88),
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Text(
                      widget.hint,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
