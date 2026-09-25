import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/app_info.dart';
import '../../../onboarding/data/onboarding_repository.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Durée minimale d'affichage — laisse le temps à 2-3 pulsations du logo
  static const _minDisplay = Duration(milliseconds: 2600);

  // Apparition initiale
  late final AnimationController _introController;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  // Pulsation du logo (« respiration ») après l'apparition
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _introController, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _introController, curve: Curves.easeOutBack),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _introController.forward().whenComplete(() {
      if (mounted) _pulseController.repeat(reverse: true);
    });
    _start();
  }

  Future<void> _start() async {
    // Futur emplacement de la vérification de mise à jour forcée (guide §8).
    final results = await Future.wait([
      ref.read(onboardingRepositoryProvider).hasSeenOnboarding(),
      Future<void>.delayed(_minDisplay),
    ]);
    if (!mounted) return;

    final hasSeenOnboarding = results.first as bool;
    context.go(hasSeenOnboarding ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _pulse,
                  child: Image.asset(
                    'assets/images/logo_symbol_light.png',
                    height: 120,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  AppInfo.name,
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppInfo.tagline,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textOnPrimary.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
