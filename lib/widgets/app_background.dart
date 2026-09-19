import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Animated gradient + soft glow background placed behind app content.
class AppBackground extends StatefulWidget {
  const AppBackground({super.key, this.child});

  final Widget? child;

  @override
  State<AppBackground> createState() => _AppBackgroundState();
}

class _AppBackgroundState extends State<AppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final emerald = const Color(0xFF10B981);
    final violet = const Color(0xFF7C4DFF);
    final indigo = const Color(0xFF3D5AFE);

    final base = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? const [
              Color(0xFF16203A),
              Color(0xFF132B3C),
              Color(0xFF2A1745),
            ]
          : const [
              Color(0xFFE6F7F0),
              Color(0xFFE7F0FF),
              Color(0xFFF3EBFF),
            ],
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(decoration: BoxDecoration(gradient: base)),
            _Glow(
              color: emerald.withValues(alpha: dark ? 0.20 : 0.28),
              size: 340,
              position: Offset(
                0.15 + 0.22 * math.sin(2 * math.pi * t),
                0.20 + 0.10 * math.cos(2 * math.pi * t * 0.6),
              ),
            ),
            _Glow(
              color: violet.withValues(alpha: dark ? 0.18 : 0.22),
              size: 380,
              position: Offset(
                0.82 + 0.14 * math.cos(2 * math.pi * (t + 0.33)),
                0.78 + 0.12 * math.sin(2 * math.pi * (t + 0.15)),
              ),
            ),
            _Glow(
              color: indigo.withValues(alpha: dark ? 0.13 : 0.16),
              size: 300,
              position: Offset(
                0.60 + 0.16 * math.sin(2 * math.pi * (t + 0.6)),
                0.08 + 0.10 * math.cos(2 * math.pi * (t + 0.4)),
              ),
            ),
            ?child,
          ],
        );
      },
      child: widget.child,
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, required this.position});

  final Color color;
  final double size;
  final Offset position;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.sizeOf(context);
    return Positioned(
      left: media.width * position.dx - size / 2,
      top: media.height * position.dy - size / 2,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withValues(alpha: 0.0)],
            ),
          ),
        ),
      ),
    );
  }
}