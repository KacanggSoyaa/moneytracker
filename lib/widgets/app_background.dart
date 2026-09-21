import 'dart:math' as math;
import 'dart:ui';
import 'dart:ui' as ui;

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
  final math.Random _random = math.Random(42);
  late final List<_Star> _stars =
      List.generate(72, (_) => _Star.random(_random));

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
              Color(0xFF000000),
              Color(0xFF02030A),
              Color(0xFF060313),
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
            if (dark)
              CustomPaint(
                painter: _SpacePainter(
                  stars: _stars,
                  elapsed:
                      _controller.lastElapsedDuration?.inMilliseconds ?? 0,
                ),
              ),
            _Glow(
              color: emerald.withValues(alpha: dark ? 0.10 : 0.28),
              size: 340,
              position: Offset(
                0.15 + 0.22 * math.sin(2 * math.pi * t),
                0.20 + 0.10 * math.cos(2 * math.pi * t * 0.6),
              ),
            ),
            _Glow(
              color: violet.withValues(alpha: dark ? 0.10 : 0.22),
              size: 380,
              position: Offset(
                0.82 + 0.14 * math.cos(2 * math.pi * (t + 0.33)),
                0.78 + 0.12 * math.sin(2 * math.pi * (t + 0.15)),
              ),
            ),
            _Glow(
              color: indigo.withValues(alpha: dark ? 0.07 : 0.16),
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

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.baseAlpha,
    required this.phase,
    required this.speed,
  });

  factory _Star.random(math.Random r) => _Star(
        x: r.nextDouble(),
        y: r.nextDouble(),
        size: 0.6 + r.nextDouble() * 1.7,
        baseAlpha: 0.35 + r.nextDouble() * 0.6,
        phase: r.nextDouble() * 2 * math.pi,
        speed: 0.6 + r.nextDouble() * 2.2,
      );

  final double x;
  final double y;
  final double size;
  final double baseAlpha;
  final double phase;
  final double speed;
}

class _ShootingStarSpec {
  const _ShootingStarSpec({
    required this.period,
    required this.delay,
    required this.duration,
    required this.from,
    required this.to,
  });

  final int period;
  final int delay;
  final int duration;
  final Offset from;
  final Offset to;
}

class _SpacePainter extends CustomPainter {
  _SpacePainter({required this.stars, required this.elapsed});

  final List<_Star> stars;
  final int elapsed;

  static const _shooting = [
    _ShootingStarSpec(
      period: 7000,
      delay: 1200,
      duration: 800,
      from: Offset(0.78, 0.08),
      to: Offset(-0.6, 1.0),
    ),
    _ShootingStarSpec(
      period: 11000,
      delay: 5600,
      duration: 900,
      from: Offset(0.55, 0.04),
      to: Offset(-0.9, 1.2),
    ),
    _ShootingStarSpec(
      period: 16500,
      delay: 2400,
      duration: 1000,
      from: Offset(0.92, 0.22),
      to: Offset(-0.4, 0.7),
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    for (final s in stars) {
      final twinkle =
          0.5 + 0.5 * math.sin(2 * math.pi * s.speed * (elapsed / 1000) + s.phase);
      final alpha = (twinkle * s.baseAlpha).clamp(0.0, 1.0);
      final center = Offset(s.x * w, s.y * h);
      canvas.drawCircle(
        center,
        s.size * 2.6,
        Paint()..color = Colors.white.withValues(alpha: alpha * 0.18),
      );
      canvas.drawCircle(
        center,
        s.size,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
    _paintMoon(canvas, w, h);
    _paintShootingStars(canvas, w, h);
  }

  void _paintMoon(Canvas canvas, double w, double h) {
    final baseR = math.min(w, h) * 0.12;
    final bob =
        math.sin(2 * math.pi * (elapsed / 9000)) * baseR * 0.12;
    final cx = w * 0.82;
    final cy = h * 0.15 + bob;

    canvas.drawCircle(
      Offset(cx, cy),
      baseR * 3.0,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          baseR * 3.0,
          [
            const Color(0xFFFFF6D8).withValues(alpha: 0.32),
            Colors.transparent,
          ],
        ),
    );

    canvas.drawCircle(
      Offset(cx, cy),
      baseR,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx + baseR * 0.35, cy - baseR * 0.35),
          baseR,
          const [Color(0xFFFDFCF7), Color(0xFFEDEBDF), Color(0xFFB4B0A0)],
          const [0.0, 0.55, 1.0],
        ),
    );

    final rot = 2 * math.pi * (elapsed % 30000) / 30000;
    const craters = <(Offset, double)>[
      (Offset(0.30, 0.25), 0.9),
      (Offset(-0.05, 0.55), 1.3),
      (Offset(0.45, 0.70), 0.7),
      (Offset(-0.35, 0.15), 0.55),
      (Offset(0.05, -0.15), 0.6),
    ];
    for (final (spot, scale) in craters) {
      final off = Offset(
        spot.dx * math.cos(rot) - spot.dy * math.sin(rot),
        spot.dx * math.sin(rot) + spot.dy * math.cos(rot),
      );
      final r = baseR * 0.16 * scale;
      final center = Offset(cx + off.dx * baseR, cy + off.dy * baseR);
      canvas.drawCircle(
        center,
        r,
        Paint()..color = const Color(0xFFB9B6A8).withValues(alpha: 0.5),
      );
      canvas.drawCircle(
        Offset(center.dx + r * 0.2, center.dy + r * 0.2),
        r * 0.85,
        Paint()..color = const Color(0xFFDAD7CA).withValues(alpha: 0.7),
      );
    }
  }

  void _paintShootingStars(Canvas canvas, double w, double h) {
    for (final spec in _shooting) {
      final cycle = (elapsed + spec.delay) % spec.period;
      if (cycle >= spec.duration) continue;
      final u = cycle / spec.duration;
      final tailParam = math.max(0.0, u - 0.12);
      final head = Offset(
        (spec.from.dx + (spec.to.dx - spec.from.dx) * u) * w,
        (spec.from.dy + (spec.to.dy - spec.from.dy) * u) * h,
      );
      final tail = Offset(
        (spec.from.dx + (spec.to.dx - spec.from.dx) * tailParam) * w,
        (spec.from.dy + (spec.to.dy - spec.from.dy) * tailParam) * h,
      );
      final fade = 1.0 - u * u;
      final gradient = ui.Gradient.linear(
        tail,
        head,
        [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.85 * fade),
        ],
      );
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round
          ..shader = gradient,
      );
      canvas.drawCircle(
        head,
        1.8,
        Paint()..color = Colors.white.withValues(alpha: 0.9 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_SpacePainter oldDelegate) =>
      oldDelegate.elapsed != elapsed || oldDelegate.stars != stars;
}