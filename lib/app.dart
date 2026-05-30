import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class RaagaFlowApp extends ConsumerWidget {
  const RaagaFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the themeProvider so the app rebuilds when the user switches themes.
    ref.watch(themeProvider);
    
    final router = createRouter();
    return MaterialApp.router(
      title: 'RaagaFlow',
      theme: darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
