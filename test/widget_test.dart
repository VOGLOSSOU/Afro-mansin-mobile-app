import 'package:afro_mansin/core/utils/app_info.dart';
import 'package:afro_mansin/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Premier lancement : splash puis onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: AmaApp()));

    expect(find.text(AppInfo.name), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Passer'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
  });

  testWidgets('Onboarding déjà vu : splash puis accueil', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_seen': true});
    await tester.pumpWidget(const ProviderScope(child: AmaApp()));

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Accueil — à venir'), findsOneWidget);
  });
}
