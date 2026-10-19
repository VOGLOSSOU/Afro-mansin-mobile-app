import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/catalogue.dart';
import 'catalogue_providers.dart';

/// Seul l'identifiant du pays est mémorisé, jamais le catalogue.
class CountryPreference extends StateNotifier<AsyncValue<int?>> {
  CountryPreference() : super(const AsyncLoading()) {
    _restore();
  }
  static const key = 'catalogue_country_id';
  int _revision = 0;

  Future<void> _restore() async {
    final revision = _revision;
    int? id;
    try {
      id = (await SharedPreferences.getInstance()).getInt(key);
    } catch (_) {
      // Une préférence inaccessible ne bloque pas le catalogue en ligne.
    }
    if (mounted && revision == _revision) state = AsyncData(id);
  }

  Future<bool> select(Country country) async {
    _revision++;
    state = AsyncData(country.id);
    try {
      return await (await SharedPreferences.getInstance()).setInt(
        key,
        country.id,
      );
    } catch (_) {
      return false;
    }
  }
}

final countryPreferenceProvider =
    StateNotifierProvider<CountryPreference, AsyncValue<int?>>(
      (ref) => CountryPreference(),
    );

final selectedCountryProvider = Provider<AsyncValue<Country?>>((ref) {
  final preference = ref.watch(countryPreferenceProvider);
  final countries = ref.watch(countriesProvider);
  return preference.when(
    loading: () => const AsyncLoading(),
    error: (error, stack) => AsyncError(error, stack),
    data: (savedId) => countries.whenData((items) {
      if (items.isEmpty) return null;
      for (final country in items) {
        if (country.id == savedId) return country;
      }
      for (final country in items) {
        final name = country.name.trim().toLowerCase();
        if (name == 'bénin' || name == 'benin') return country;
      }
      return items.first;
    }),
  );
});
