import 'dart:math' as math;

import 'package:elements/models/world_model.dart';
import 'package:elements/state/progress_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorldSelectScreen extends ConsumerWidget {
  const WorldSelectScreen({super.key});

  static const _colors = <int, Color>{
    1: Color(0xFFFF885E),
    2: Color(0xFF61CBEA),
    3: Color(0xFFC99D68),
    4: Color(0xFF8ED17C),
  };

  static const _icons = <int, IconData>{
    1: Icons.local_fire_department_rounded,
    2: Icons.water_drop_rounded,
    3: Icons.landscape_rounded,
    4: Icons.park_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF171321), Color(0xFF211C2C), Color(0xFF141923)],
          ),
        ),
        child: SafeArea(
          child: progress.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Could not load progress: $error')),
            data: (playerProgress) => LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFFFD166),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ELEMENT SHIFT',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2.1,
                                          ),
                                    ),
                                    const Text(
                                      'THE ROOTWAYS  ·  Choose your path',
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 11,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _HeaderAction(
                                icon: Icons.storefront_outlined,
                                tooltip: 'Store',
                                onTap: () => context.go('/store'),
                              ),
                              _HeaderAction(
                                icon: Icons.tune_rounded,
                                tooltip: 'Settings',
                                onTap: () => context.go('/settings'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFD166),
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${playerProgress.levelResults.values.fold<int>(0, (sum, result) => sum + result.stars)} stars',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.diamond_rounded,
                                color: Color(0xFFB7F1FF),
                                size: 18,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${playerProgress.elementShardBalance} shards',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: constraints.maxWidth,
                            height: (constraints.maxWidth * 1.24).clamp(
                              470.0,
                              690.0,
                            ),
                            child: LayoutBuilder(
                              builder: (context, mapConstraints) {
                                final width = mapConstraints.maxWidth;
                                final height = mapConstraints.maxHeight;
                                final cardWidth = math.min(width * 0.43, 250.0);
                                final cardHeight = 112.0;
                                Widget worldNode(WorldModel world) {
                                  final color = _colors[world.id]!;
                                  final unlocked = playerProgress
                                      .isWorldUnlocked(world.id);
                                  final completed =
                                      List.generate(
                                            world.levelCount,
                                            (i) => i + 1,
                                          )
                                          .where(
                                            (i) =>
                                                playerProgress
                                                    .levelResults['level_w${world.id}_${i.toString().padLeft(2, '0')}']
                                                    ?.completed ??
                                                false,
                                          )
                                          .length;
                                  return SizedBox(
                                    width: cardWidth,
                                    height: cardHeight,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: unlocked
                                            ? () => context.go(
                                                '/worlds/${world.id}',
                                              )
                                            : null,
                                        child: Ink(
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF292536,
                                            ).withValues(alpha: 0.97),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: unlocked
                                                  ? color.withValues(alpha: 0.8)
                                                  : Colors.white12,
                                              width: unlocked ? 1.5 : 1,
                                            ),
                                            boxShadow: unlocked
                                                ? [
                                                    BoxShadow(
                                                      color: color.withValues(
                                                        alpha: 0.16,
                                                      ),
                                                      blurRadius: 22,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 42,
                                                  height: 42,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: color.withValues(
                                                      alpha: 0.18,
                                                    ),
                                                  ),
                                                  child: Icon(
                                                    unlocked
                                                        ? _icons[world.id]
                                                        : Icons.lock_rounded,
                                                    color: unlocked
                                                        ? color
                                                        : Colors.white38,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'ROOT ${world.id}',
                                                        style: TextStyle(
                                                          color: color,
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          letterSpacing: 1.4,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        world.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        unlocked
                                                            ? '$completed / ${world.levelCount} cleared'
                                                            : 'Locked · earn 30 stars',
                                                        style: const TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final centerUnlocked = playerProgress
                                    .isLevelUnlocked(4, 15);
                                return Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _RootwayPainter(
                                          width: width,
                                          height: height,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: height * 0.12,
                                      child: worldNode(launchWorlds[0]),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: height * 0.12,
                                      child: worldNode(launchWorlds[1]),
                                    ),
                                    Positioned(
                                      left: 0,
                                      bottom: height * 0.08,
                                      child: worldNode(launchWorlds[2]),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: height * 0.08,
                                      child: worldNode(launchWorlds[3]),
                                    ),
                                    Positioned(
                                      left:
                                          (width -
                                              math.min(width * 0.42, 220)) /
                                          2,
                                      top: (height - 120) / 2,
                                      width: math.min(width * 0.42, 220),
                                      height: 120,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          onTap: centerUnlocked
                                              ? () => context.go(
                                                  '/play/level_w4_15',
                                                )
                                              : null,
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: centerUnlocked
                                                    ? const [
                                                        Color(0xFF685032),
                                                        Color(0xFF332938),
                                                      ]
                                                    : const [
                                                        Color(0xFF393443),
                                                        Color(0xFF242130),
                                                      ],
                                              ),
                                              border: Border.all(
                                                color: const Color(0xFFFFD166)
                                                    .withValues(
                                                      alpha: centerUnlocked
                                                          ? 0.9
                                                          : 0.28,
                                                    ),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFFFD166)
                                                      .withValues(
                                                        alpha: centerUnlocked
                                                            ? 0.18
                                                            : 0.04,
                                                      ),
                                                  blurRadius: 28,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  centerUnlocked
                                                      ? Icons.wb_sunny_rounded
                                                      : Icons.lock_rounded,
                                                  color: const Color(
                                                    0xFFFFD166,
                                                  ),
                                                  size: 30,
                                                ),
                                                const SizedBox(height: 5),
                                                const Text(
                                                  'THE HEARTWOOD',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    letterSpacing: 1.3,
                                                  ),
                                                ),
                                                Text(
                                                  centerUnlocked
                                                      ? 'Final trial · Level 15'
                                                      : 'Open the four roots to reach it',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white60,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const Text(
                            'Four roots. Four elemental paths. One heart at the center.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    icon: Icon(icon, color: Colors.white70),
    style: IconButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.07),
    ),
  );
}

class _RootwayPainter extends CustomPainter {
  const _RootwayPainter({required this.width, required this.height});
  final double width;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(width / 2, height / 2);
    final roots = [
      Offset(width * 0.24, height * 0.23),
      Offset(width * 0.76, height * 0.23),
      Offset(width * 0.24, height * 0.78),
      Offset(width * 0.76, height * 0.78),
    ];
    final colors = [
      const Color(0xFFFF885E),
      const Color(0xFF61CBEA),
      const Color(0xFFC99D68),
      const Color(0xFF8ED17C),
    ];
    for (var i = 0; i < roots.length; i++) {
      final start = roots[i];
      final direction = start.dx < center.dx ? 1.0 : -1.0;
      final curve = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(
          start.dx + direction * 42,
          start.dy + (center.dy - start.dy) * 0.3,
          center.dx - direction * 38,
          center.dy - (center.dy - start.dy) * 0.25,
          center.dx,
          center.dy,
        );
      final paint = Paint()
        ..color = colors[i].withValues(alpha: 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(curve, paint);
      final branch = Path()
        ..moveTo(start.dx, start.dy + (start.dy < center.dy ? 24 : -24))
        ..cubicTo(
          start.dx + direction * 18,
          start.dy + (center.dy - start.dy) * 0.32,
          center.dx - direction * 50,
          center.dy + (start.dy < center.dy ? -52 : 52),
          center.dx,
          center.dy,
        );
      canvas.drawPath(
        branch,
        Paint()
          ..color = colors[i].withValues(alpha: 0.14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    }
    for (var i = 0; i < 44; i++) {
      final angle = i * 2.399;
      final radius = 9 + (i % 11) * 5.0;
      final p = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawCircle(
        p,
        i % 4 == 0 ? 1.6 : 0.8,
        Paint()..color = const Color(0xFFFFD166).withValues(alpha: 0.34),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RootwayPainter oldDelegate) =>
      oldDelegate.width != width || oldDelegate.height != height;
}
