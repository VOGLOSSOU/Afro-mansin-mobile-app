import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/utils/app_info.dart';

void main() {
  // runApp immédiat — aucun await avant le premier rendu (guide §7b).
  // Les chargements se font dans le SplashScreen.
  runApp(const ProviderScope(child: AmaApp()));
}

class AmaApp extends ConsumerWidget {
  const AmaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
