import 'package:elements/shell/codex/codex_screen.dart';
import 'package:elements/shell/game/game_screen.dart';
import 'package:elements/shell/home/home_screen.dart';
import 'package:elements/shell/level_select/level_select_screen.dart';
import 'package:elements/shell/level_select/world_select_screen.dart';
import 'package:elements/shell/settings/settings_screen.dart';
import 'package:elements/shell/store/store_screen.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/worlds',
      builder: (context, state) => const WorldSelectScreen(),
    ),
    GoRoute(
      path: '/worlds/:worldId',
      builder: (context, state) {
        final worldId = int.tryParse(state.pathParameters['worldId'] ?? '') ?? 1;
        return LevelSelectScreen(worldId: worldId);
      },
    ),
    GoRoute(
      path: '/play/:levelId',
      builder: (context, state) {
        final levelId = state.pathParameters['levelId'] ?? 'level_w1_01';
        return GameScreen(levelId: levelId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/store',
      builder: (context, state) => const StoreScreen(),
    ),
    GoRoute(
      path: '/codex',
      builder: (context, state) => const CodexScreen(),
    ),
  ],
);
