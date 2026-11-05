import 'dart:async';
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
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../home/data/models/service_item_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  String _selectedCategory = 'الكل';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final hc = context.read<HomeController>();
      if (hc.allServices.isEmpty && hc.status != HomeStatus.loading) {
        hc.loadHomeData();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim();
        });
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  bool _matchesCategoryName(String a, String b) {
    final al = a.toLowerCase();
    final bl = b.toLowerCase();
    if (al == bl) return true;
    if (al.contains('قاع') && bl.contains('قاع')) return true;
    if ((al.contains('شاليه') || al.contains('استراح')) &&
        (bl.contains('شاليه') || bl.contains('استراح'))) return true;
    if (al.contains('كيك') && bl.contains('كيك')) return true;
    if (al.contains('صور') && bl.contains('صور')) return true;
    if (al.contains('ديكور') && bl.contains('ديكور')) return true;
    if (al.contains('زهر') && bl.contains('زهر')) return true;
    return false;
  }

  bool _matchesCategory(ServiceItemModel service, String filter) {
    if (filter == 'الكل') return true;

    final cat = service.category.trim().toLowerCase();
    final filterLower = filter.trim().toLowerCase();

    // المطابقة المباشرة الحرفية أو الاحتواء
    if (cat == filterLower || cat.contains(filterLower) || filterLower.contains(cat)) {
      return true;
    }

    // قاعات وصالات
    if (filterLower.contains('قاع') || filterLower.contains('صال')) {
      return cat.contains('قاع') || cat.contains('صال');
    }

    // شاليهات واستراحات
    if (filterLower.contains('شاليه') || filterLower.contains('استراح')) {
      return cat.contains('شاليه') ||
          cat.contains('استراح') ||
          service.title.toLowerCase().contains('شاليه') ||
          service.title.toLowerCase().contains('استراحة');
    }

    // كيك وحلويات
    if (filterLower.contains('كيك') || filterLower.contains('حلو')) {
      return cat.contains('كيك') ||
          cat.contains('حلو') ||
          service.title.toLowerCase().contains('كيك');
    }

    // تصوير ومصورين
    if (filterLower.contains('صور') ||
        filterLower.contains('فوتو') ||
        filterLower.contains('مونتاج')) {
      return cat.contains('صور') ||
          cat.contains('فوتو') ||
          cat.contains('مونتاج') ||
          service.title.toLowerCase().contains('تصوير');
    }

    // كوشات وديكور وتنسيق
    if (filterLower.contains('كوش') ||
        filterLower.contains('ديكور') ||
        filterLower.contains('تنسيق')) {
      return cat.contains('كوش') ||
          cat.contains('ديكور') ||
          cat.contains('تنسيق');
    }

    // زهور وبوكيهات
    if (filterLower.contains('زهر') ||
        filterLower.contains('ورد') ||
        filterLower.contains('بوكيه')) {
      return cat.contains('زهر') ||
          cat.contains('ورد') ||
          cat.contains('بوكيه');
    }

    // منشدين وفنانين
    if (filterLower.contains('منشد') || filterLower.contains('موسيق')) {
      return cat.contains('منشد') || cat.contains('موسيق');
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final homeController = context.watch<HomeController>();

    // عرض حالة التحميل إن كانت البيانات لا تزال قيد الجلب لأول مرة
    if (homeController.status == HomeStatus.loading &&
        homeController.allServices.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingView(message: 'جاري تحميل الخدمات والتصنيفات...'),
      );
    }

    final query = _searchQuery.toLowerCase();

    // قائمة التصنيفات الثابتة والديناميكية المضمونة دائماً
    final List<String> availableCategories = [
      'الكل',
      'قاعات المناسبات',
      'استراحات وشاليهات',
      'الكيك والحلويات',
      'تصوير ومونتاج',
      'تنسيق وديكور الحفلات',
      'تنسيق الزهور والهدايا',
    ];

    // إضافة أي تصنيف إضافي قادم من السيرفر غير مكرر
    for (final cat in homeController.categories) {
      final t = cat.title.trim();
      if (t.isNotEmpty &&
          !availableCategories.any((c) => _matchesCategoryName(c, t))) {
        availableCategories.add(t);
      }
    }

    // فلترة الخدمات بالبحث النصي والتصنيف
    final filteredServices = homeController.allServices.where((s) {
      // 1. فحص التصنيف الذكي
      final matchesCat = _matchesCategory(s, _selectedCategory);
      if (!matchesCat) return false;

      // 2. فحص النص
      if (query.isEmpty) return true;
      final titleMatch = s.title.toLowerCase().contains(query);
      final locMatch = s.location.toLowerCase().contains(query);
      final descMatch = s.description.toLowerCase().contains(query);
      final catMatch = s.category.toLowerCase().contains(query);

      // دعم الاستعلام عن شاليه أو استراحة حتى لو لم تكن الكلمة بالعنوان
      final isChaletQuery = query.contains('شاليه') || query.contains('استراح');
      final chaletMatch = isChaletQuery &&
          (s.category.contains('استراح') || s.category.contains('شاليه'));

      return titleMatch || locMatch || descMatch || catMatch || chaletMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'استكشاف القاعات والخدمات',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Search Input
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  textDirection: TextDirection.rtl,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: AppStrings.searchPlaceholder,
                    hintTextDirection: TextDirection.rtl,
                    border: InputBorder.none,
                    // enabledBorder:OutlineInputBorder(
                    //   borderRadius: BorderRadius.circular(50),
                    //   borderSide: const BorderSide(
                    //     color: AppColors.primary,
                    //     width: 1
                    //   ),
                    // ),
                    enabledBorder: InputBorder.none,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1
                      ),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: _clearSearch,
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemCount: availableCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = availableCategories[index];
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderDefault,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Services List
              Expanded(
                child: filteredServices.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.search_off_rounded,
                        title: 'لم يتم العثور على نتائج',
                        description:
                            'جرب البحث بكلمات مختلفة أو تغيير التصنيف المحدد.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 90),
                        itemCount: filteredServices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, index) {
                          final service = filteredServices[index];
                          FavoritesController? favCtrl;
                          try {
                            favCtrl = Provider.of<FavoritesController>(context);
                          } catch (_) {}
                          final isFav = (favCtrl != null && !(favCtrl.isLoading && favCtrl.isEmpty))
                              ? favCtrl.isFavorite(service.id)
                              : service.isFavorite;
                          return ServiceCard(
                            width: double.infinity,
                            title: service.title,
                            location: service.location,
                            priceText: service.formattedPrice,
                            rating: service.rating,
                            imageUrl: service.imageUrl,
                            isFavorite: isFav,
                            onTap: () async {
                              final favController = context.read<FavoritesController>();
                              await Navigator.of(context).pushNamed(
                                AppRoutes.serviceDetails,
                                arguments: service,
                              );
                              favController.loadFavorites();
                            },
                            onFavoriteToggle: () {
                              _handleFavoriteToggle(service.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleFavoriteToggle(String serviceId) async {
    final authController = context.read<AuthController>();
    if (!authController.isAuthenticated) {
      if (!mounted) return;
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
      await context.read<HomeController>().toggleFavorite(serviceId);
      if (!mounted) return;
      context.read<FavoritesController>().loadFavorites();
    } catch (e) {
      if (!mounted) return;
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
