
import 'package:flutter/material.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/auth_gate_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/main_nav/presentation/screens/main_navigation_screen.dart';
import '../../features/home/data/models/service_item_model.dart';
import '../../features/service_details/presentation/screens/service_details_screen.dart';
import '../../features/smart_planning/presentation/screens/smart_planning_input_screen.dart';
import '../../features/smart_planning/presentation/screens/smart_plan_result_screen.dart';
import '../../features/smart_planning/presentation/screens/package_customization_screen.dart';
import '../../features/bookings/presentation/screens/booking_date_screen.dart';
import '../../features/bookings/presentation/screens/booking_success_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/home/data/models/category_model.dart';
import '../../features/home/presentation/screens/category_services_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String authGate = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String mainNav = '/main-nav';
  static const String categoryServices = '/category-services';
  static const String serviceDetails = '/service-details';
  static const String smartPlanningInput = '/smart-planning-input';
  static const String smartPlanResult = '/smart-plan-result';
  static const String packageCustomization = '/package-customization';
  static const String bookingDate = '/booking-date';
  static const String bookingSuccess = '/booking-success';
  static const String notifications = '/notifications';
  static const String support = '/support';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case authGate:
        return MaterialPageRoute(builder: (_) => const AuthGateScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case mainNav:
        final initialIndex =
            (settings.arguments is int) ? settings.arguments as int : 0;
        return MaterialPageRoute(
            builder: (_) => MainNavigationScreen(initialIndex: initialIndex));
      case categoryServices:
        final category = settings.arguments as CategoryModel;
        return MaterialPageRoute(
            builder: (_) => CategoryServicesScreen(category: category));
      case serviceDetails:
        final service = settings.arguments as ServiceItemModel;
        return MaterialPageRoute(
            builder: (_) => ServiceDetailsScreen(service: service));
      case smartPlanningInput:
        return MaterialPageRoute(
            builder: (_) => const SmartPlanningInputScreen());
      case smartPlanResult:
        return MaterialPageRoute(builder: (_) => const SmartPlanResultScreen());
      case packageCustomization:
        return MaterialPageRoute(
            builder: (_) => const PackageCustomizationScreen());
      case bookingDate:
        final service = settings.arguments as ServiceItemModel?;
        return MaterialPageRoute(
            builder: (_) => BookingDateScreen(service: service));
      case bookingSuccess:
        final bookingCode = settings.arguments as String? ?? 'KH-84920';
        return MaterialPageRoute(
            builder: (_) => BookingSuccessScreen(bookingCode: bookingCode));
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case support:
        Map<String, dynamic>? args;
        if (settings.arguments is Map<String, dynamic>) {
          args = settings.arguments as Map<String, dynamic>;
        }
        return MaterialPageRoute(
          builder: (_) => SupportScreen(
            initialBookingId: args?['bookingId'] as String?,
            initialBookingCode: args?['bookingCode'] as String?,
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const AuthGateScreen());
    }
  }
}
