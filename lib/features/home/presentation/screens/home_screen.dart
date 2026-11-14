import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/service_card.dart';
import '../../data/models/category_model.dart';
import '../../data/models/service_item_model.dart';
import '../controllers/home_controller.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeController>().loadHomeData();
    });
  }

  void _openServiceDetails(ServiceItemModel service) {
    Navigator.of(context).pushNamed(
      AppRoutes.serviceDetails,
      arguments: service,
    ).then((_) {
      if (mounted) {
        context.read<FavoritesController>().loadFavorites(silent: true);
      }
    });
  }

  Future<void> _handleFavoriteToggle(String serviceId) async {
    final authController = context.read<AuthController>();
    if (!authController.isAuthenticated) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى تسجيل الدخول لإضافة الخدمة إلى المفضلة',
            style: GoogleFonts.cairo(),
          ),
          action: SnackBarAction(
            label: 'تسجيل الدخول',
            textColor: AppColors.goldYellow,
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.login);
            },
          ),
        ),
      );
      return;
    }

    try {
      final homeController = context.read<HomeController>();
      final favoritesController = context.read<FavoritesController>();

      final isNowFav = await homeController.toggleFavorite(serviceId);
      if (isNowFav) {
        final service = homeController.allServices.firstWhere(
          (s) => s.id == serviceId,
        );
        favoritesController.addFavoriteLocally(service);
      } else {
        favoritesController.removeFavoriteLocally(serviceId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.cairo(),
            ),
          ),
        );
      }
    }
  }

  void _openCategoryServices(CategoryModel category) {
    Navigator.of(context).pushNamed(
      AppRoutes.categoryServices,
      arguments: category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeController = context.watch<HomeController>();
    final notifController = context.watch<NotificationsController>();
    FavoritesController? favCtrl;
    try {
      favCtrl = context.watch<FavoritesController>();
    } catch (_) {}

    if (favCtrl != null && !favCtrl.isInitialized && homeController.allServices.isNotEmpty) {
      favCtrl.seedFavorites(
        homeController.allServices.where((s) => s.isFavorite).map((s) => s.id),
      );
    }

    if (homeController.status == HomeStatus.loading &&
        homeController.allServices.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const LoadingView(message: 'جاري تحميل الخدمات والتصنيفات...'),
      );
    }

    if (homeController.status == HomeStatus.error &&
        homeController.allServices.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorStateView(
          message: homeController.errorMessage ?? 'حدث خطأ في تحميل البيانات',
          onRetry: () => homeController.loadHomeData(),
        ),
      );
    }

    if (homeController.status == HomeStatus.success &&
        homeController.allServices.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: EmptyStateView(
          icon: Icons.event_busy_rounded,
          title: 'لا توجد خدمات متاحة حالياً',
          description: 'لم يتم العثور على خدمات منشورة في قاعدة البيانات حالياً.',
          buttonText: 'تحديث الصفحة',
          onButtonPressed: () => homeController.loadHomeData(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveContainer(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => homeController.loadHomeData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 44), // balance
                        Text(
                          AppStrings.welcome,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        // Notification Bell
                        Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: AppColors.borderLight),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(AppRoutes.notifications);
                                },
                              ),
                            ),
                            if (notifController.unreadCount > 0)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${notifController.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Search Bar Prompt
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onNavigateTab != null) {
                          widget.onNavigateTab!(1); // navigate to Explore tab
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              //color: AppColors.primary,
                              color: AppColors.textTertiary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppStrings.searchPlaceholder,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Hero Promotional Carousel
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 10, bottom: 6),
                  //   child: SizedBox(
                  //     height: 190,
                  //     child: ListView(
                  //       scrollDirection: Axis.horizontal,
                  //       padding: const EdgeInsets.symmetric(horizontal: 20),
                  //       children: [
                  //         _buildPromoBanner(
                  //           title: 'حفلات الأعراس الفاخرة',
                  //           subtitle: 'أرقى القاعات وتجهيزات الكوش الكاملة',
                  //           imageUrl: AppAssets.heroWedding,
                  //         ),
                  //         const SizedBox(width: 14),
                  //         _buildPromoBanner(
                  //           title: 'استراحات وشاليهات خاصة',
                  //           subtitle:
                  //               'أفضل الأماكن لقضاء أسعد اللحظات العائلية',
                  //           imageUrl: AppAssets.heroChalet,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  // AI Smart Planner Banner (Direct highlight)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primaryDark,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome,
                                      color: AppColors.goldYellow,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'المساعد الذكي للمناسبات',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.champagneLight,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'خطط مناسبتك باحترافية',
                                  style: GoogleFonts.cairo(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'احصل على باقة مخصصة تناسب ميزانيتك وعدد ضيوفك',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed(
                                        AppRoutes.smartPlanningInput);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  
                                  label: Text(
                                    'ابدأ التخطيط الآن',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  
                                ),
                              ],
                            ),
                          ),
                          // const SizedBox(width: 8),
                          // Container(
                          //   width: 64,
                          //   height: 64,
                          //   decoration: BoxDecoration(
                          //     color: Colors.white.withOpacity(0.12),
                          //     shape: BoxShape.circle,
                          //   ),
                          //   child: const Icon(
                          //     Icons.celebration_rounded,
                          //     color: AppColors.goldYellow,
                          //     size: 34,
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),

                  // Categories Section (Grid matching Stitch design)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: Text(
                      AppStrings.categories,
                      style: GoogleFonts.cairo(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  // Categories Dynamic List (From Supabase or Fallback)
                  if (homeController.categories.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: homeController.categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final cat = homeController.categories[index];
                          return _buildCategoryTile(
                            cat,
                            145,
                          );
                        },
                      ),
                    )
                  else if (homeController.status == HomeStatus.loading)
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: 5,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, __) => Container(
                          width: 145,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSection,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                  // Service Sections: 1. Venues (قاعات وصالات المناسبات)
                  _buildServiceSection(
                    title: 'قاعات وصالات المناسبات',
                    services: homeController.venues,
                    onFavoriteToggle: _handleFavoriteToggle,
                    onServiceTap: _openServiceDetails,
                  ),

                  // Service Sections: 2. Decor (تنسيق وديكور الحفلات)
                  _buildServiceSection(
                    title: 'تنسيق وديكور الحفلات',
                    services: homeController.kosha,
                    onFavoriteToggle: _handleFavoriteToggle,
                    onServiceTap: _openServiceDetails,
                  ),

                  // Service Sections: 3. Cakes (الكيك والحلويات)
                  _buildServiceSection(
                    title: 'الكيك والحلويات',
                    services: homeController.cakes,
                    onFavoriteToggle: _handleFavoriteToggle,
                    onServiceTap: _openServiceDetails,
                  ),

                  // Service Sections: 4. Flowers (تنسيق الزهور والهدايا)
                  _buildServiceSection(
                    title: 'تنسيق الزهور والهدايا',
                    services: homeController.flowers,
                    onFavoriteToggle: _handleFavoriteToggle,
                    onServiceTap: _openServiceDetails,
                  ),

                  // Service Sections: 5. Photography (تصوير ومونتاج)
                  _buildServiceSection(
                    title: 'تصوير ومونتاج سينمائي',
                    services: homeController.photographers,
                    onFavoriteToggle: _handleFavoriteToggle,
                    onServiceTap: _openServiceDetails,
                  ),

                  // Service Sections: 6. Rest houses (استراحات وشاليهات)
                  _buildServiceSection(
                    title: 'استراحات وشاليهات',
                    services: homeController.restHouses,
                    onFavoriteToggle: _handleFavoriteToggle,
                    onServiceTap: _openServiceDetails,
                  ),

                  // Service Sections: 7. All Services (كافة الخدمات المتاحة)
                  _buildServiceSection(
                    title: 'كافة الخدمات المتاحة',
                    services: homeController.allServices,
                    onFavoriteToggle: _handleFavoriteToggle,
                    onServiceTap: _openServiceDetails,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildPromoBanner({
  //   required String title,
  //   required String subtitle,
  //   required String imageUrl,
  // }) {
  //   return Container(
  //     width: 300,
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(color: AppColors.borderLight),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 3),
  //         ),
  //       ],
  //     ),
  //     child: ClipRRect(
  //       borderRadius: BorderRadius.circular(20),
  //       child: Stack(
  //         fit: StackFit.expand,
  //         children: [
  //           Image.network(
  //             imageUrl,
  //             fit: BoxFit.cover,
  //             errorBuilder: (_, __, ___) =>
  //                 Container(color: AppColors.surfaceSection),
  //           ),
  //           Container(
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 begin: Alignment.bottomCenter,
  //                 end: Alignment.topCenter,
  //                 colors: [
  //                   Colors.black.withOpacity(0.75),
  //                   Colors.black.withOpacity(0.1),
  //                   Colors.transparent,
  //                 ],
  //               ),
  //             ),
  //           ),
  //           Positioned(
  //             bottom: 14,
  //             right: 14,
  //             left: 14,
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text(
  //                   title,
  //                   style: GoogleFonts.cairo(
  //                     fontSize: 15,
  //                     fontWeight: FontWeight.w800,
  //                     color: Colors.white,
  //                   ),
  //                 ),
  //                 Text(
  //                   subtitle,
  //                   style: GoogleFonts.cairo(
  //                     fontSize: 11,
  //                     fontWeight: FontWeight.w500,
  //                     color: Colors.white.withOpacity(0.85),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildCategoryTile(CategoryModel category, double width) {
    final imageUrl = category.imageUrl.isNotEmpty
        ? category.imageUrl
        : AppAssets.venueGrandHall;
    final bool isNetwork =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

    return GestureDetector(
      onTap: () => _openCategoryServices(category),
      child: Container(
        width: width,
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isNetwork)
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.surfaceSection),
                )
              else if (imageUrl.isNotEmpty)
                Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.surfaceSection),
                )
              else
                Container(color: AppColors.surfaceSection),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 0,
                left: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    category.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceSection({
    required String title,
    required List<ServiceItemModel> services,
    required void Function(String id) onFavoriteToggle,
    required void Function(ServiceItemModel service) onServiceTap,
  }) {
    if (services.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  }
                },
                child: Text(
                  AppStrings.viewAll,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 275,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: services.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final service = services[index];
              FavoritesController? favCtrl;
              try {
                favCtrl = context.watch<FavoritesController>();
              } catch (_) {}
              final isFav = (favCtrl != null && favCtrl.isInitialized)
                  ? favCtrl.isFavorite(service.id)
                  : service.isFavorite;
              return ServiceCard(
                title: service.title,
                location: service.location,
                priceText: service.formattedPrice,
                rating: service.rating,
                imageUrl: service.imageUrl,
                images: service.allImages,
                isFavorite: isFav,
                onTap: () => onServiceTap(service),
                onFavoriteToggle: () => onFavoriteToggle(service.id),
              );
            },
          ),
        ),
      ],
    );
  }
}
