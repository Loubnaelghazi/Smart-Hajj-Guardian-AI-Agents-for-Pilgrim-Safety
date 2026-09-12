import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_strings.dart';
import 'providers/session_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/trip_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier(0);
  ref.listen(sessionProvider, (_, next) {
    notifier.value++;
  });
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, route) {
      final session = ref.read(sessionProvider);
      final path = route.uri.path;
      if (session.isLoading) return path == '/splash' ? null : '/splash';
      if (session.value == null) {
        return path == '/onboarding' ? null : '/onboarding';
      }
      if (path == '/onboarding' || path == '/splash') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      ShellRoute(
        builder: (_, state, child) =>
            TripShell(path: state.uri.path, child: child),
        routes: [
          for (final path in [
            'home',
            'group',
            'safety',
            'profile',
            'safe-zone',
            'return',
            'emergency',
          ])
            GoRoute(
              path: '/$path',
              builder: (_, _) => TripScreen(page: path),
            ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    notifier.dispose();
  });
  return router;
});

class GuardianApp extends ConsumerWidget {
  const GuardianApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionProvider);
    ref.watch(healthProvider);
    return MaterialApp.router(
      title: 'Smart Hajj Guardian',
      debugShowCheckedModeBanner: false,
      theme: guardianTheme(),
      locale: ref.watch(localeProvider).value ?? const Locale('en'),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: const [
        AppStrings.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
    );
  }
}
