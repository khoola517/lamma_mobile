// ignore_for_file: avoid_print, depend_on_referenced_packages, unnecessary_overrides, deprecated_member_use
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:khadematy/core/config/supabase_config.dart';
import 'package:khadematy/features/smart_planning/data/models/smart_plan_models.dart';
import 'package:khadematy/features/smart_planning/data/repositories/supabase_smart_planning_repository.dart';
import 'package:khadematy/features/smart_planning/presentation/controllers/smart_planning_controller.dart';

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

  setUpAll(() async {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.cleanUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (_) {}
  });

  group('Smart Planning Supabase Integration Tests', () {
    test('SupabaseSmartPlanningRepository fetches real categories from Supabase', () async {
      final repo = SupabaseSmartPlanningRepository();
      final categories = await repo.getCategories();

      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.title.contains('قاعات')), isTrue);
      print('Categories fetched: ${categories.map((c) => c.title).toList()}');
    });

    test('SupabaseSmartPlanningRepository generates dynamic packages without creating rows in packages table', () async {
      final client = SupabaseConfig.client;
      // Get count of packages before
      final beforeCount = (await client.from('packages').select('id')).length;

      final repo = SupabaseSmartPlanningRepository();
      final request = SmartPlanRequest(
        eventType: 'حفل زفاف',
        budget: 800000,
        guestsCount: 100,
        eventDate: DateTime.now().add(const Duration(days: 30)),
        requestedServices: ['ae10f6c7-ea18-4b23-8823-369c57981ce8', '2a7e3a4c-bdc1-46c0-8b17-577202f3b027'],
      );

      final result = await repo.generatePlan(request);
      expect(result.packages, isNotEmpty);
      expect(result.customizableServices, isNotEmpty);
      expect(result.packages.first.price, greaterThan(0));

      // Verify count of packages in database is UNCHANGED!
      final afterCount = (await client.from('packages').select('id')).length;
      expect(afterCount, equals(beforeCount), reason: 'Packages table must not have new rows inserted on preview');
    });

    test('SupabaseSmartPlanningRepository rejects low budget with clear message', () async {
      final repo = SupabaseSmartPlanningRepository();
      final lowBudgetRequest = SmartPlanRequest(
        eventType: 'حفل زفاف',
        budget: 500, // Unrealistic low budget
        guestsCount: 100,
        eventDate: DateTime.now().add(const Duration(days: 30)),
        requestedServices: ['ae10f6c7-ea18-4b23-8823-369c57981ce8'],
      );

      expect(
        () async => await repo.generatePlan(lowBudgetRequest),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('الميزانية المدخلة أقل من الحد الأدنى'),
        )),
      );
    });

    test('SmartPlanningController manages state and category loading via Supabase repository', () async {
      final controller = SmartPlanningController(repository: SupabaseSmartPlanningRepository());

      await controller.loadCategories();
      expect(controller.categories, isNotEmpty);

      controller.updateBudget(600000);
      expect(controller.request.budget, 600000);
    });
  });
}
