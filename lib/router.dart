import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shirne_dialog/shirne_dialog.dart';

import 'models/play_mode.dart';
import 'screens/home_screen.dart';
import 'screens/board_screen.dart';
import 'screens/live_match_screen.dart';
import 'setting.dart';
import 'widgets/game_wrapper.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// App-wide router. The ShellRoute keeps GameWrapper alive as the permanent
/// ancestor for all main screens, so gamer.scale stays in sync.
/// Settings and Live run on the root navigator (full-screen push).
final appRouter = GoRouter(
  navigatorKey: MyDialog.navigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return GameWrapper(isMain: true, child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/game',
          builder: (context, state) {
            final mode = state.extra! as PlayMode;
            return BoardScreen(mode: mode);
          },
        ),
      ],
    ),
    GoRoute(
      parentNavigatorKey: MyDialog.navigatorKey,
      path: '/settings',
      builder: (context, state) => const SettingPage(),
    ),
    GoRoute(
      parentNavigatorKey: MyDialog.navigatorKey,
      path: '/live',
      builder: (context, state) => const LiveMatchScreen(),
    ),
  ],
);
