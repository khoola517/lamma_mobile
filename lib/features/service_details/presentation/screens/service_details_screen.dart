import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../home/data/models/service_item_model.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';
import '../../../reviews/presentation/widgets/reviews_section_widget.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final ServiceItemModel service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final PageController _imageController = PageController();
  int _currentImageIndex = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _imageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _stopAutoPlay();
    _autoPlayTimer = Timer.periodic(const Duration(milliseconds: 3200), (timer) {
      if (!mounted || !_imageController.hasClients) return;
      final images = _getResolvedImages();
      if (images.length <= 1) return;

      final nextPage = (_currentImageIndex + 1) % images.length;
      _imageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  List<String> _getResolvedImages() {
    try {
      final homeController = context.read<HomeController>();
      final item = homeController.allServices.firstWhere(
        (s) => s.id == widget.service.id,
        orElse: () => widget.service,
      );
      final imgs = item.allImages;
      if (imgs.isNotEmpty) return imgs;
    } catch (_) {}
    return widget.service.allImages;
  }

  Widget _buildHeaderImage(BuildContext context, String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _headerPlaceholder(context),
      );
    } else if (url.startsWith('data:image')) {
      try {
        final comma = url.indexOf(',');
        final b64 = comma != -1 ? url.substring(comma + 1) : url;
        return Image.memory(
          base64Decode(b64),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _headerPlaceholder(context),
        );
      } catch (_) {
        return _headerPlaceholder(context);
      }
    } else if (url.isNotEmpty) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _headerPlaceholder(context),
      );
    } else {
      return _headerPlaceholder(context);
    }
  }

  Widget _headerPlaceholder(BuildContext context) {
    return Container(
      color: context.surfaceSection,
      child: Center(
        child: Icon(Icons.image, size: 50, color: context.textTertiary),
      ),
    );
  }

  Color _badgeBgColor(BuildContext context) =>
      context.isDarkMode ? AppColors.darkSurfaceWarm : const Color(0xFFFDF8F3);

  Color _badgeBorderColor(BuildContext context) => context.isDarkMode
      ? AppColors.darkBorderChipSelected
      : const Color(0xFFF4E8DC);

  Color _warmAccentColor(BuildContext context) =>
      context.isDarkMode ? AppColors.goldYellow : const Color(0xFF8C5A2B);

  @override
  Widget build(BuildContext context) {
    final homeController = context.watch<HomeController>();
    final favoritesController = context.watch<FavoritesController>();

    final homeItem = homeController.allServices.firstWhere(
      (s) => s.id == widget.service.id,
      orElse: () => widget.service,
    );
    final isFav = favoritesController.isInitialized
        ? favoritesController.isFavorite(widget.service.id)
        : homeItem.isFavorite;
    final currentItem = homeItem.copyWith(isFavorite: isFav);

    // الصور الحقيقية من Supabase
    final images = currentItem.allImages.isNotEmpty
        ? currentItem.allImages
        : (currentItem.imageUrl.isNotEmpty ? [currentItem.imageUrl] : <String>[]);

    // السعة الحقيقية من Supabase
    final hasCapacity = currentItem.capacity != null && currentItem.capacity!.trim().isNotEmpty;
    final capacityDisplay = hasCapacity ? currentItem.capacity!.trim() : 'مرنة';

    // المدينة والموقع الحقيقي من Supabase
    final hasLocation = currentItem.location.trim().isNotEmpty;
    final locationDisplay = hasLocation ? currentItem.location.trim() : 'غير محدد';

    // السعر الفعلي من Supabase
    final priceDisplay = currentItem.price > 0 ? currentItem.formattedPrice : 'حسب الطلب';

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          // المحتوى القابل للتمرير
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. صور الخدمة الحقيقية من Supabase
                SizedBox(
                  height: 300,
                  child: Stack(
                    children: [
                      if (images.isNotEmpty)
                        PageView.builder(
                          controller: _imageController,
                          itemCount: images.length,
                          onPageChanged: (i) {
                            setState(() => _currentImageIndex = i);
                            _startAutoPlay();
                          },
                          itemBuilder: (context, index) {
                            return _buildHeaderImage(context, images[index]);
                          },
                        )
                      else
                        Container(
                          color: context.surfaceSection,
                          child: Center(
                            child: Icon(Icons.image_not_supported_outlined, size: 50, color: context.textTertiary),
                          ),
                        ),

                      // تدرج علوي لأزرار التحكم
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 90,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // شريط الأزرار العلوي (رجوع، مشاركة، مفضلة)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 20),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.share_outlined,
                                        color: Colors.white, size: 20),
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      currentItem.isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: currentItem.isFavorite
                                          ? Colors.redAccent
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () async {
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
                                        final isNowFav = await homeController.toggleFavorite(currentItem.id);
                                        if (isNowFav) {
                                          favoritesController.addFavoriteLocally(currentItem.copyWith(isFavorite: true));
                                        } else {
                                          favoritesController.removeFavoriteLocally(currentItem.id);
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
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
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // أزرار التنقل اليدوي السريع بين الصور (تظهر إذا كانت أكثر من صورة)
                      if (images.length > 1)
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // زر الصورة السابقة
                                GestureDetector(
                                  onTap: () {
                                    final prev = (_currentImageIndex - 1 + images.length) % images.length;
                                    _imageController.animateToPage(
                                      prev,
                                      duration: const Duration(milliseconds: 380),
                                      curve: Curves.easeInOutCubic,
                                    );
                                    _startAutoPlay();
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.38),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_left_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                // زر الصورة التالية
                                GestureDetector(
                                  onTap: () {
                                    final next = (_currentImageIndex + 1) % images.length;
                                    _imageController.animateToPage(
                                      next,
                                      duration: const Duration(milliseconds: 380),
                                      curve: Curves.easeInOutCubic,
                                    );
                                    _startAutoPlay();
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.38),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // مؤشرات صور العرض (إذا كانت أكثر من صورة)
                      if (images.length > 1)
                        Positioned(
                          bottom: 38,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              images.length,
                              (index) => GestureDetector(
                                onTap: () {
                                  _imageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 380),
                                    curve: Curves.easeInOutCubic,
                                  );
                                  _startAutoPlay();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: _currentImageIndex == index ? 22 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white54,
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // عدّاد الصور
                      if (images.length > 1)
                        Positioned(
                          bottom: 34,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1} / ${images.length}',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 2. الحاوية المتداخلة مع الهيدر
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.backgroundColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // عنوان الخدمة والتصنيف الفعلي من Supabase
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentItem.title,
                                    style: GoogleFonts.cairo(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: context.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    currentItem.category,
                                    style: GoogleFonts.cairo(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // التقييم الحقيقي من جدول reviews في Supabase
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _badgeBgColor(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: _badgeBorderColor(context)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 16, color: AppColors.brandGold),
                                  const SizedBox(width: 4),
                                  Text(
                                    currentItem.rating > 0
                                        ? currentItem.rating.toStringAsFixed(1)
                                        : 'جديد',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: _warmAccentColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // 3. بطاقات المؤشرات السريعة (السعر - السعة - المدينة) من بيانات Supabase الفعلية
                        Row(
                          children: [
                            // السعر الفعلي
                            Expanded(
                              child: _buildQuickStatCard(
                                context: context,
                                icon: Icons.account_balance_wallet_outlined,
                                value: priceDisplay,
                                label: 'السعر',
                              ),
                            ),
                            const SizedBox(width: 10),
                            // السعة الفعلية
                            Expanded(
                              child: _buildQuickStatCard(
                                context: context,
                                icon: Icons.people_outline_rounded,
                                value: capacityDisplay,
                                label: 'السعة',
                              ),
                            ),
                            const SizedBox(width: 10),
                            // المدينة الفعلية
                            Expanded(
                              child: _buildQuickStatCard(
                                context: context,
                                icon: Icons.location_on_outlined,
                                value: locationDisplay,
                                label: 'المدينة',
                              ),
                            ),
                          ],
                        ),

                        // 4. بطاقة "نبذة" (تظهر فقط إذا كان هناك وصف مسجل في Supabase)
                        if (currentItem.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSectionContainer(
                            context: context,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'نبذة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currentItem.description.trim(),
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    height: 1.7,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 5. بطاقة "المناسبات المتاحة" (تظهر فقط من قائمة occasions في Supabase)
                        if (currentItem.occasions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSectionContainer(
                            context: context,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المناسبات المتاحة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: currentItem.occasions.map((occ) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _badgeBgColor(context),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: _badgeBorderColor(context)),
                                      ),
                                      child: Text(
                                        occ,
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _warmAccentColor(context),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 6. بطاقة "أوقات الدوام" (تظهر فقط إذا كانت مسجلة في working_hours في Supabase)
                        if (currentItem.workingHours.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSectionContainer(
                            context: context,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'أوقات الدوام',
                                      style: GoogleFonts.cairo(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: context.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _badgeBgColor(context),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color: _badgeBorderColor(context)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_month_outlined,
                                            size: 13,
                                            color: _warmAccentColor(context),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${currentItem.workingHours.length} أيام عمل',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: _warmAccentColor(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  height: 96,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: currentItem.workingHours.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 10),
                                    itemBuilder: (context, index) {
                                      final item = currentItem.workingHours[index];
                                      return _buildDayCard(
                                        context: context,
                                        day: item['day'] ?? '',
                                        status: item['status'] ?? 'متاح',
                                        time: item['time'] ?? '',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // 7. المميزات والتجهيزات الفعلية من Supabase (features)
                        if (currentItem.features.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildSectionContainer(
                            context: context,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المميزات والتجهيزات',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: currentItem.features.map((feature) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: context.surfaceWarm,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: context.borderDefault),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle_rounded,
                                              size: 16,
                                              color: _warmAccentColor(context)),
                                          const SizedBox(width: 6),
                                          Text(
                                            feature,
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // // 8. الموقع والعنوان الفعلي من Supabase
                        // if (hasAddress) ...[
                        //   const SizedBox(height: 16),
                        //   _buildSectionContainer(
                        //     child: Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: [
                        //         Text(
                        //           'الموقع',
                        //           style: GoogleFonts.cairo(
                        //             fontSize: 16,
                        //             fontWeight: FontWeight.w800,
                        //             color: const Color(0xFF1E2538),
                        //           ),
                        //         ),
                        //         const SizedBox(height: 10),
                        //         Container(
                        //           padding: const EdgeInsets.all(12),
                        //           decoration: BoxDecoration(
                        //             color: const Color(0xFFFDFBF7),
                        //             borderRadius: BorderRadius.circular(12),
                        //             border: Border.all(
                        //                 color: const Color(0xFFEFEBE4)),
                        //           ),
                        //           child: Row(
                        //             children: [
                        //               Container(
                        //                 width: 40,
                        //                 height: 40,
                        //                 decoration: BoxDecoration(
                        //                   color: const Color(0xFFFDF8F3),
                        //                   borderRadius: BorderRadius.circular(10),
                        //                   border: Border.all(
                        //                       color: const Color(0xFFF5EAE0)),
                        //                 ),
                        //                 child: const Icon(
                        //                   Icons.location_on_rounded,
                        //                   color: Color(0xFF8C5A2B),
                        //                   size: 22,
                        //                 ),
                        //               ),
                        //               const SizedBox(width: 12),
                        //               Expanded(
                        //                 child: Column(
                        //                   crossAxisAlignment:
                        //                       CrossAxisAlignment.start,
                        //                   children: [
                        //                     Text(
                        //                       locationDisplay,
                        //                       style: GoogleFonts.cairo(
                        //                         fontSize: 14,
                        //                         fontWeight: FontWeight.w700,
                        //                         color: const Color(0xFF1E2538),
                        //                       ),
                        //                     ),
                        //                     Text(
                        //                       addressDisplay,
                        //                       style: GoogleFonts.cairo(
                        //                         fontSize: 12,
                        //                         fontWeight: FontWeight.w500,
                        //                         color: const Color(0xFF8F95A3),
                        //                       ),
                        //                     ),
                        //                   ],
                        //                 ),
                        //               ),
                        //             ],
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        // ],

                        const SizedBox(height: 8),
                        Divider(color: context.borderLight, height: 32),
                        const SizedBox(height: 4),

                        // 9. قسم التقييمات الحي من Supabase (جدول reviews)
                        ReviewsSectionWidget(
                          serviceId: currentItem.id,
                          serviceTitle: currentItem.title,
                          initialRating: currentItem.rating,
                          initialReviewsCount: currentItem.reviewsCount,
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 10. شريط الحجز السفلي المتصل ببيانات الخدمة الفعلية
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: BoxDecoration(
                color: context.surfaceCard,
                border: Border(
                    top: BorderSide(color: context.borderLight, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                        context.isDarkMode ? 0.25 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ResponsiveContainer(
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'السعر الإجمالي',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.textTertiary,
                            ),
                          ),
                          Text(
                            priceDisplay,
                            style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CustomButton(
                          text: 'حــجــــز',
                          height: 46,
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.bookingDate,
                              arguments: currentItem,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة الأقسام (Section Card)
  Widget _buildSectionContainer({
    required BuildContext context,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.18 : 0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // بطاقات المؤشرات السريعة (السعر - السعة - المدينة)
  Widget _buildQuickStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: context.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDarkMode ? 0.18 : 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: context.isDarkMode
                ? AppColors.goldYellow
                : const Color(0xFFA07449),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // بطاقة يوم العمل
  Widget _buildDayCard({
    required BuildContext context,
    required String day,
    required String status,
    required String time,
  }) {
    final accentColor = _warmAccentColor(context);
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceWarm,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                day,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          Text(
            status,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accentColor,
            ),
          ),
          if (time.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: context.surfaceSection,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: accentColor,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
