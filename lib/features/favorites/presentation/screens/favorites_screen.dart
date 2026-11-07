import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/service_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../controllers/favorites_controller.dart';

class FavoritesScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const FavoritesScreen({super.key, this.onNavigateTab});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      if (authController.isAuthenticated) {
        context.read<FavoritesController>().loadFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final favoritesController = context.watch<FavoritesController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.favoritesTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildBody(context, authController, favoritesController),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuthController authController,
    FavoritesController favoritesController,
  ) {
    // 1. User not logged in
    if (!authController.isAuthenticated) {
      return _buildGuestState(context);
    }

    // 2. Loading State
    if (favoritesController.isLoading && favoritesController.isEmpty) {
      return const LoadingView(message: 'جاري تحميل المفضلة من سحابة خِدمتي...');
    }

    // 3. Error State
    if (favoritesController.errorMessage != null &&
        favoritesController.isEmpty) {
      return _buildErrorState(context, favoritesController);
    }

    // 4. Empty State
    if (favoritesController.isEmpty) {
      return EmptyStateView(
        icon: Icons.favorite_border_rounded,
        title: 'قائمة المفضلة فارغة',
        description:
            'احفظ القاعات والخدمات التي تعجبك بالضغط على أيقونة القلب لتصل إليها بسهولة هنا.',
        buttonText: 'استكشف الخدمات الآن',
        onButtonPressed: () {
          if (widget.onNavigateTab != null) {
            widget.onNavigateTab!(1);
          }
        },
      );
    }

    // 5. Populated List with Refresh Indicator
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceCard,
      onRefresh: () => favoritesController.loadFavorites(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 10, bottom: 90),
        itemCount: favoritesController.favoriteServices.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final service = favoritesController.favoriteServices[index];
          return ServiceCard(
            width: double.infinity,
            title: service.title,
            location: service.location,
            priceText: service.formattedPrice,
            rating: service.rating,
            imageUrl: service.imageUrl,
            isFavorite: true,
            onTap: () {
              Navigator.of(context)
                  .pushNamed(
                    AppRoutes.serviceDetails,
                    arguments: service,
                  )
                  .then((_) {
                favoritesController.loadFavorites(silent: true);
              });
            },
            onFavoriteToggle: () async {
              try {
                await favoritesController.removeFavorite(service.id);
                if (context.mounted) {
                  context
                      .read<HomeController>()
                      .updateFavoriteStatus(service.id, false);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تمت إزالة "${service.title}" من المفضلة',
                        style: GoogleFonts.cairo(),
                      ),
                      action: SnackBarAction(
                        label: 'تراجع',
                        textColor: AppColors.goldYellow,
                        onPressed: () async {
                          await favoritesController.toggleFavorite(service);
                          if (context.mounted) {
                            context
                                .read<HomeController>()
                                .updateFavoriteStatus(service.id, true);
                          }
                        },
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تعذر حذف الخدمة من السحابة: ${e.toString().replaceAll('Exception: ', '')}',
                        style: GoogleFonts.cairo(),
                      ),
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildGuestState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'سجّل الدخول لعرض مفضلتك',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'احفظ قاعاتك وخدماتك المفضلة وقم بمزامنتها تلقائياً عبر سحابة خِدمتي (Supabase) للوصول إليها في أي وقت ومن أي جهاز.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final favCtrl = context.read<FavoritesController>();
                  await Navigator.of(context).pushNamed(AppRoutes.login);
                  favCtrl.loadFavorites();
                },
                icon: const Icon(Icons.login_rounded, size: 20),
                label: Text(
                  'تسجيل الدخول / إنشاء حساب',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(1);
                }
              },
              child: Text(
                'استكشف الخدمات كزائر',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    FavoritesController controller,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'تعذر تحميل المفضلة من السحابة',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage ?? 'تأكد من اتصالك بالإنترنت وحاول مجدداً.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.loadFavorites(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'إعادة المحاولة',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
