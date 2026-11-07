import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:khadematy/app/theme/theme_controller.dart';
import 'package:khadematy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:khadematy/features/auth/domain/repositories/auth_repository.dart';
import 'package:khadematy/features/auth/data/models/user_model.dart';
import 'package:khadematy/features/profile/presentation/screens/profile_screen.dart';

class _MockAuthRepository implements AuthRepository {
  UserModel? get currentUser => const UserModel(
        id: 'usr-1',
        name: 'أحمد محمد',
        email: 'ahmed@example.com',
        phone: '771234567',
      );

  bool get isAuthenticated => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state defaults to light mode or given initialMode', () {
      final controller = ThemeController(initialMode: ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);
      expect(controller.isDarkMode, false);
      expect(controller.themeModeName, 'الوضع الفاتح');
    });

    test('setThemeMode updates themeMode and isDarkMode', () async {
      final controller = ThemeController(initialMode: ThemeMode.light);
      await controller.setThemeMode(ThemeMode.dark);

      expect(controller.themeMode, ThemeMode.dark);
      expect(controller.isDarkMode, true);
      expect(controller.themeModeName, 'الوضع الداكن');

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('khadematy_theme_mode'), 'dark');
    });

    test('toggleDarkMode switches between light and dark', () async {
      final controller = ThemeController(initialMode: ThemeMode.light);
      await controller.toggleDarkMode(true);
      expect(controller.isDarkMode, true);

      await controller.toggleDarkMode(false);
      expect(controller.isDarkMode, false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('khadematy_theme_mode'), 'light');
    });

    test('setThemeMode to system saves system', () async {
      final controller = ThemeController(initialMode: ThemeMode.light);
      await controller.setThemeMode(ThemeMode.system);
      expect(controller.themeMode, ThemeMode.system);
      expect(controller.themeModeName, 'تلقائي (حسب النظام)');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('khadematy_theme_mode'), 'system');
    });
  });

  group('ProfileScreen Theme Setting Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('ProfileScreen renders theme toggle switch and can toggle it', (tester) async {
      final themeCtrl = ThemeController(initialMode: ThemeMode.light);
      final authCtrl = AuthController(repository: _MockAuthRepository());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeController>.value(value: themeCtrl),
            ChangeNotifierProvider<AuthController>.value(value: authCtrl),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Theme Mode item in Account Settings
      expect(find.text('المظهر (الوضع الليلي)'), findsOneWidget);
      expect(find.text('الوضع الفاتح'), findsOneWidget);

      // Verify Switch is present
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Tap Switch to toggle to Dark Mode
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(themeCtrl.isDarkMode, true);
      expect(find.text('الوضع الداكن'), findsOneWidget);

      // Tap Theme row to open Selection Modal BottomSheet
      await tester.tap(find.text('المظهر (الوضع الليلي)'));
      await tester.pumpAndSettle();

      expect(find.text('اختيار مظهر التطبيق'), findsOneWidget);
      expect(find.text('الوضع الفاتح (النهاري)'), findsOneWidget);
      expect(find.text('الوضع الداكن (الليلي)'), findsOneWidget);
      expect(find.text('تلقائي (حسب نظام الجهاز)'), findsOneWidget);

      // Select Light mode from bottom sheet
      await tester.tap(find.text('الوضع الفاتح (النهاري)'));
      await tester.pumpAndSettle();

      expect(themeCtrl.isDarkMode, false);
      expect(find.text('الوضع الفاتح'), findsOneWidget);
    });
  });
}
