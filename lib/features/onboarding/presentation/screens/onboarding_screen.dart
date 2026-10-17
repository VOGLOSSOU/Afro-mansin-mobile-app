import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/app_info.dart';
import '../../data/onboarding_repository.dart';
import '../widgets/onboarding_page.dart';

// Images plein écran (portrait) — originaux dans design/onboarding/.
const _pages = [
  OnboardingPage(
    imageAsset: 'assets/images/onboarding_1.jpg',
    title: "Le savoir des plantes d'Afrique",
    body: 'Trouvez les plantes médicinales utilisées dans votre pays : '
        'par maladie, en cas d\'urgence ou pour vos besoins en vitamines.',
  ),
  OnboardingPage(
    imageAsset: 'assets/images/onboarding_2.jpg',
    title: 'Dans votre langue',
    body: 'Chaque plante a ses noms en fon, yoruba, adja, dendi… '
        'Écoutez-les pour la reconnaître et en parler autour de vous.',
  ),
  OnboardingPage(
    imageAsset: 'assets/images/onboarding_3.jpg',
    imageAlignment: Alignment(0.5, 0), // la tasse est à droite
    title: 'Une information, pas une ordonnance',
    body: AppInfo.medicalDisclaimer,
    highlightBody: true,
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Précharge les images pour un défilement sans flash
    for (final page in _pages) {
      precacheImage(
        AssetImage(page.imageAsset),
        context,
        onError: (_, _) {}, // image pas encore fournie : fond de secours
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Icônes de la barre de statut en clair, sur l'image
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primaryDark,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              children: _pages,
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  height: OnboardingPage.topBarHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Visibility(
                      visible: !_isLastPage,
                      child: TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                        child: const Text('Passer'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  height: OnboardingPage.controlsHeight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
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
                ),
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
            color: isActive
                ? AppColors.textOnPrimary
                : AppColors.textOnPrimary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        );
      }),
    );
  }
}
