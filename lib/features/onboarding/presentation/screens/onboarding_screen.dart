import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/app_info.dart';
import '../../data/onboarding_repository.dart';
import '../widgets/onboarding_page.dart';

const _pages = [
  OnboardingPage(
    icon: Icons.eco_rounded,
    color: AppColors.primary,
    title: "Le savoir des plantes d'Afrique",
    body: 'Trouvez les plantes médicinales utilisées dans votre pays : '
        'par maladie, en cas d\'urgence ou pour vos besoins en vitamines.',
  ),
  OnboardingPage(
    icon: Icons.record_voice_over_rounded,
    color: AppColors.accent,
    title: 'Dans votre langue',
    body: 'Chaque plante a ses noms en fon, yoruba, adja, dendi… '
        'Écoutez-les pour la reconnaître et en parler autour de vous.',
  ),
  OnboardingPage(
    icon: Icons.health_and_safety_rounded,
    color: AppColors.secondary,
    title: 'Une information, pas une ordonnance',
    body: AppInfo.medicalDisclaimer,
    note: '48 heures après avoir consulté une recette, nous vous demanderons '
        'comment elle s\'est passée, pour améliorer les conseils.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentIndex = 0;

  bool get _isLastPage => _currentIndex == _pages.length - 1;

  static const _pageTransition = Duration(milliseconds: 350);

  void _next() {
    _pageController.nextPage(duration: _pageTransition, curve: Curves.easeOut);
  }

  // « Passer » mène à la dernière page plutôt que de sauter l'onboarding :
  // l'avertissement médical doit toujours être vu.
  void _skip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: _pageTransition,
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    await ref.read(onboardingRepositoryProvider).markOnboardingSeen();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                // Garde la hauteur réservée sur la dernière page pour éviter un saut
                child: Visibility(
                  visible: !_isLastPage,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TextButton(
                    onPressed: _skip,
                    child: const Text('Passer'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                children: _pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                children: [
                  _PageDots(count: _pages.length, current: _currentIndex),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _isLastPage ? _finish : _next,
                    child: Text(_isLastPage ? 'Commencer' : 'Suivant'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int count;
  final int current;

  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}
