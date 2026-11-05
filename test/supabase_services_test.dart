// ignore_for_file: avoid_print, depend_on_referenced_packages, unnecessary_overrides, deprecated_member_use
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khadematy/core/config/supabase_config.dart';
import 'package:khadematy/features/home/data/repositories/supabase_services_repository.dart';

class _AllowAllHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  HttpOverrides.global = _AllowAllHttpOverrides();

  test('Fetch categories and services from real Supabase project', () async {
    await Supabase.initialize(
      url: SupabaseConfig.cleanUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );

    final repo = SupabaseServicesRepository();

    final categories = await repo.getCategories();
    expect(categories.isNotEmpty, true);
    print('SUCCESS: Fetched ${categories.length} categories:');
    for (var c in categories) {
      print(' - ${c.title}');
    }

    final services = await repo.getAllServices();
    expect(services.isNotEmpty, true);
    print('\nSUCCESS: Fetched ${services.length} services:');
    for (var s in services) {
      print(' - [${s.category}] ${s.title}: ${s.formattedPrice}');
    }

    // TEST: Verify getServicesByCategoryId for 2 different categories
    expect(categories.length >= 2, true);
    final cat1 = categories[0];
    final cat2 = categories[1];

    final servicesCat1 = await repo.getServicesByCategoryId(cat1.id);
    final servicesCat2 = await repo.getServicesByCategoryId(cat2.id);

    print('\nSUCCESS: Category 1 [${cat1.title}] (id: ${cat1.id}) services: ${servicesCat1.length}');
    for (var s in servicesCat1) {
      print('   * ${s.title} (categoryId: ${s.categoryId})');
      expect(s.categoryId, cat1.id);
    }

    print('\nSUCCESS: Category 2 [${cat2.title}] (id: ${cat2.id}) services: ${servicesCat2.length}');
    for (var s in servicesCat2) {
      print('   * ${s.title} (categoryId: ${s.categoryId})');
      expect(s.categoryId, cat2.id);
    }

    // Ensure services do not overlap
    final cat1Ids = servicesCat1.map((s) => s.id).toSet();
    final cat2Ids = servicesCat2.map((s) => s.id).toSet();
    expect(cat1Ids.intersection(cat2Ids).isEmpty, true);
  });
}
