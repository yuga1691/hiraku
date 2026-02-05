import 'package:flutter/material.dart';

class CyberBackground extends StatelessWidget {
  const CyberBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _CyberBackdrop(),
        child,
      ],
    );
  }
}

class _CyberBackdrop extends StatelessWidget {
  const _CyberBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF05070B),
                  Color(0xFF0B111A),
                  Color(0xFF05070B),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(),
            ),
          ),
          Align(
            alignment: const Alignment(0.8, -0.8),
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00E5FF).withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withOpacity(0.25),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: const Alignment(-0.9, 0.85),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7CFF6B).withOpacity(0.12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7CFF6B).withOpacity(0.22),
                    blurRadius: 50,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8FF7FF).withOpacity(0.06)
      ..strokeWidth = 1;

    const gap = 36.0;
    for (double x = 0; x <= size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
