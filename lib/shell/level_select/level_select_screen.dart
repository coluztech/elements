import 'package:elements/models/world_model.dart';
import 'package:elements/state/progress_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LevelSelectScreen extends ConsumerWidget {
  const LevelSelectScreen({super.key, required this.worldId});
  final int worldId;

  static const _worldColors = <int, Color>{
    1: Color(0xFFFF885E),
    2: Color(0xFF61CBEA),
    3: Color(0xFFC99D68),
    4: Color(0xFF8ED17C),
  };

  static const _worldOneTitles = <int, String>{
    1: 'Burn the bramble',
    2: 'Swim the flood',
    3: 'Bridge & boulder',
    4: 'Flood · flame · flood',
    5: 'Timed crossing',
    6: 'Raise the high path',
    7: 'Push, burn, ascend',
    8: 'The rootway trial',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final matches = launchWorlds.where((item) => item.id == worldId);
    final world = matches.isEmpty ? null : matches.first;
    final count = world?.levelCount ?? 0;
    final color = _worldColors[worldId] ?? const Color(0xFFFFD166);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          world == null ? 'Root Path' : 'Root ${world.id} · ${world.name}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: world == null
          ? const Center(child: Text('This root does not exist.'))
          : progress.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Could not load progress: $error')),
              data: (playerProgress) {
                final completed = List.generate(count, (i) => i + 1)
                    .where(
                      (index) =>
                          playerProgress
                              .levelResults['level_w${worldId}_${index.toString().padLeft(2, '0')}']
                              ?.completed ??
                          false,
                    )
                    .length;
                return Stack(
                  children: [
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF211D2C), Color(0xFF151821)],
                          ),
                        ),
                      ),
                    ),
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                      itemCount: count + 1,
                      itemBuilder: (context, rowIndex) {
                        if (rowIndex == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$completed / $count trails cleared',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: count == 0 ? 0 : completed / count,
                                    minHeight: 7,
                                    backgroundColor: Colors.white12,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Follow the living root. Each cleared trial opens the next.',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final index = rowIndex;
                        final levelId =
                            'level_w${worldId}_${index.toString().padLeft(2, '0')}';
                        final unlocked = playerProgress.isLevelUnlocked(
                          worldId,
                          index,
                        );
                        final result = playerProgress.levelResults[levelId];
                        final onLeft = index.isEven;
                        final isCapstone = index == count;
                        final node = SizedBox(
                          width: 48,
                          child: Column(
                            children: [
                              Container(
                                width: isCapstone ? 46 : 38,
                                height: isCapstone ? 46 : 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: result?.completed == true
                                      ? color.withValues(alpha: 0.3)
                                      : unlocked
                                      ? const Color(0xFF302B3D)
                                      : const Color(0xFF23212B),
                                  border: Border.all(
                                    color: unlocked ? color : Colors.white24,
                                    width: isCapstone ? 2.5 : 1.5,
                                  ),
                                  boxShadow: unlocked
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(
                                              alpha: 0.18,
                                            ),
                                            blurRadius: 14,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  result?.completed == true
                                      ? Icons.check_rounded
                                      : unlocked
                                      ? (isCapstone
                                            ? Icons.flag_rounded
                                            : Icons.play_arrow_rounded)
                                      : Icons.lock_rounded,
                                  color: unlocked ? color : Colors.white38,
                                  size: isCapstone ? 23 : 20,
                                ),
                              ),
                              if (index < count)
                                Container(
                                  width: 2,
                                  height: 42,
                                  color: result?.completed == true
                                      ? color.withValues(alpha: 0.55)
                                      : Colors.white12,
                                ),
                            ],
                          ),
                        );
                        final card = SizedBox(
                          height: 76,
                          child: FilledButton.tonal(
                            onPressed: unlocked
                                ? () => context.go('/play/$levelId')
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: unlocked
                                  ? const Color(0xFF302B3D)
                                  : const Color(0xFF25232D),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white38,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: unlocked
                                      ? color.withValues(alpha: 0.36)
                                      : Colors.white10,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCapstone
                                          ? 'ROOT’S CROWN'
                                          : 'TRIAL ${index.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: color,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 10,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isCapstone
                                          ? 'Final ascent'
                                          : worldId == 1
                                          ? (_worldOneTitles[index] ??
                                                'Element puzzle')
                                          : 'Element puzzle',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                                if (result != null)
                                  Text(
                                    '★${result.stars}',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD166),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                        return Row(
                          children: [
                            if (onLeft)
                              Expanded(child: card)
                            else
                              const Expanded(child: SizedBox()),
                            node,
                            if (!onLeft)
                              Expanded(child: card)
                            else
                              const Expanded(child: SizedBox()),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
    );
  }
}
