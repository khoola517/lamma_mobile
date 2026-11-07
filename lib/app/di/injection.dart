import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/supabase_auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/home/domain/repositories/services_repository.dart';
import '../../features/home/data/repositories/supabase_services_repository.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../features/smart_planning/domain/repositories/smart_planning_repository.dart';
import '../../features/smart_planning/data/repositories/supabase_smart_planning_repository.dart';
import '../../features/smart_planning/presentation/controllers/smart_planning_controller.dart';
import '../../features/bookings/domain/repositories/bookings_repository.dart';
import '../../features/bookings/data/repositories/supabase_bookings_repository.dart';
import '../../features/bookings/presentation/controllers/bookings_controller.dart';
import '../../features/favorites/presentation/controllers/favorites_controller.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/data/repositories/supabase_notifications_repository.dart';
import '../../features/notifications/presentation/controllers/notifications_controller.dart';
import '../../features/reviews/domain/repositories/reviews_repository.dart';
import '../../features/reviews/data/repositories/supabase_reviews_repository.dart';
import '../../features/reviews/presentation/controllers/reviews_controller.dart';
import '../../features/support/domain/repositories/support_repository.dart';
import '../../features/support/data/repositories/supabase_support_repository.dart';
import '../../features/support/presentation/controllers/support_controller.dart';
import '../theme/theme_controller.dart';

class Injection {
  Injection._();

  static List<SingleChildWidget> get providers {
    // ربط كافة ميزات التطبيق حصرياً مع Supabase بدون أي Mock Data
    final AuthRepository authRepository = SupabaseAuthRepository();
    final ServicesRepository servicesRepository = SupabaseServicesRepository();
    final SmartPlanningRepository smartPlanningRepository =
        SupabaseSmartPlanningRepository();
    final BookingsRepository bookingsRepository = SupabaseBookingsRepository();
    final NotificationsRepository notificationsRepository =
        SupabaseNotificationsRepository();
    final ReviewsRepository reviewsRepository = SupabaseReviewsRepository();
    final SupportRepository supportRepository = SupabaseSupportRepository();

    return [
      // Theme Provider (Dark / Light Mode)
      ChangeNotifierProvider<ThemeController>(
        create: (_) => ThemeController(),
      ),

      // Auth Provider
      ChangeNotifierProvider<AuthController>(
        create: (_) => AuthController(repository: authRepository),
      ),

      // Home Provider
      ChangeNotifierProvider<HomeController>(
        create: (_) => HomeController(repository: servicesRepository),
      ),

      // Smart Planning Provider
      ChangeNotifierProvider<SmartPlanningController>(
        create: (_) =>
            SmartPlanningController(repository: smartPlanningRepository),
      ),

      // Bookings Provider
      ChangeNotifierProxyProvider<AuthController, BookingsController>(
        create: (_) => BookingsController(repository: bookingsRepository),
        update: (_, authController, bookingsController) {
          bookingsController?.onAuthChanged(authController.isAuthenticated);
          return bookingsController!;
        },
      ),

      // Favorites Provider
      ChangeNotifierProxyProvider<AuthController, FavoritesController>(
        create: (_) => FavoritesController(repository: servicesRepository),
        update: (_, authController, favoritesController) {
          favoritesController?.onAuthChanged(authController.isAuthenticated);
          return favoritesController!;
        },
      ),

      // Notifications Provider
      ChangeNotifierProxyProvider<AuthController, NotificationsController>(
        create: (_) =>
            NotificationsController(repository: notificationsRepository),
        update: (_, authController, notificationsController) {
          notificationsController?.onAuthChanged(authController.isAuthenticated);
          return notificationsController!;
        },
      ),

      // Reviews & Comments Provider
      ChangeNotifierProvider<ReviewsController>(
        create: (_) => ReviewsController(repository: reviewsRepository),
      ),

      // Support & Complaints Provider
      ChangeNotifierProxyProvider<AuthController, SupportController>(
        create: (_) => SupportController(repository: supportRepository),
        update: (_, authController, supportController) {
          supportController?.onAuthChanged(authController.isAuthenticated);
          return supportController!;
        },
      ),
    ];
  }
}
