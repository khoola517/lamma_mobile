import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khadematy/app/routes/app_routes.dart';
import 'package:khadematy/core/constants/app_assets.dart';
import 'package:khadematy/core/constants/app_colors.dart';
import 'package:khadematy/features/auth/data/models/user_model.dart';
import 'package:khadematy/features/auth/presentation/controllers/auth_controller.dart';
import 'package:khadematy/features/auth/presentation/screens/auth_gate_screen.dart';
import 'package:khadematy/features/auth/presentation/screens/login_screen.dart';
import 'package:khadematy/features/auth/presentation/screens/register_screen.dart';
import 'package:provider/provider.dart';

class MockAuthController extends ChangeNotifier implements AuthController {
  @override
  AuthStatus status = AuthStatus.unauthenticated;

  @override
  bool get isAuthenticated => status == AuthStatus.authenticated;

  @override
  String? errorMessage;

  @override
  UserModel? user;

  @override
  Future<void> checkAuth() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('App Logo and Auth Screens Tests', () {
    testWidgets(
        'AuthGateScreen has AppColors.primary background and displays logo image',
        (WidgetTester tester) async {
      final mockAuth = MockAuthController();

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.login: (_) => const Scaffold(body: Text('Login Page')),
            AppRoutes.mainNav: (_) => const Scaffold(body: Text('Home Page')),
          },
          home: ChangeNotifierProvider<AuthController>.value(
            value: mockAuth,
            child: const AuthGateScreen(),
          ),
        ),
      );

      // Verify Scaffold has AppColors.primary background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.primary));

      // Verify Image.asset with AppAssets.appLogo is present
      final imageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == AppAssets.appLogo,
      );
      expect(imageFinder, findsOneWidget);

      // Verify the old plain text "خدمتي" is NOT used as the main title
      expect(find.text('خِدمتي'), findsNothing);

      // Settle the delayed timer and navigation
      await tester.pump(const Duration(milliseconds: 1300));
      await tester.pumpAndSettle();
    });

    testWidgets('LoginScreen displays logo image at the top',
        (WidgetTester tester) async {
      final mockAuth = MockAuthController();

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.register: (_) => const Scaffold(body: Text('Register Page')),
            AppRoutes.forgotPassword: (_) => const Scaffold(body: Text('Forgot Password')),
          },
          home: ChangeNotifierProvider<AuthController>.value(
            value: mockAuth,
            child: const LoginScreen(),
          ),
        ),
      );

      final imageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == AppAssets.appLogo,
      );
      expect(imageFinder, findsOneWidget);
    });

    testWidgets('RegisterScreen displays logo image at the top',
        (WidgetTester tester) async {
      final mockAuth = MockAuthController();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthController>.value(
            value: mockAuth,
            child: const RegisterScreen(),
          ),
        ),
      );

      final imageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == AppAssets.appLogo,
      );
      expect(imageFinder, findsOneWidget);
    });
  });
}
