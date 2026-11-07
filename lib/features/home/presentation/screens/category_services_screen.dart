import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/service_card.dart';
import '../../data/models/category_model.dart';
import '../../data/models/service_item_model.dart';
import '../controllers/home_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';

/// شاشة عرض الخدمات التابعة لتصنيف محدد
/// تعرض فقط الخدمات المرتبطة بمعرّف التصنيف في Supabase
class CategoryServicesScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryServicesScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ServiceItemModel> _services = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServices();
      context.read<HomeController>().addListener(_onHomeDataChanged);
    });
  }

  void _onHomeDataChanged() {
    if (!mounted) return;
    _loadServices(silent: true);
  }

  @override
  void dispose() {
    try {
      context.read<HomeController>().removeListener(_onHomeDataChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _loadServices({bool silent = false}) async {
    if (!mounted) return;

    final homeController = context.read<HomeController>();

    // 1. فحص الخدمات المتاحة مسبقاً في الذاكرة لتجنب أي شاشة خطأ إنترنت زائفة
    final cachedServices = homeController.allServices.where((s) {
      final matchesId = s.categoryId == widget.category.id;
      final catTitle = widget.category.title.trim();
      final matchesName = catTitle.isNotEmpty &&
          (s.category.trim() == catTitle ||
              s.category.contains(catTitle) ||
              catTitle.contains(s.category));
      return matchesId || matchesName;
    }).toList();

    if (cachedServices.isNotEmpty && _services.isEmpty) {
      setState(() {
        _services = cachedServices;
        _isLoading = false;
        _errorMessage = null;
      });
      silent = true;
    }

    if (!silent && _services.isEmpty) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result =
          await homeController.getServicesByCategoryId(widget.category.id);
      if (mounted) {
        setState(() {
          if (result.isNotEmpty || _services.isEmpty) {
            _services = result.isNotEmpty ? result : cachedServices;
          }
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('CategoryServicesScreen: Error loading services: $e');
      if (mounted) {
        if (_services.isNotEmpty || cachedServices.isNotEmpty) {
          setState(() {
            if (_services.isEmpty) _services = cachedServices;
            _isLoading = false;
            _errorMessage = null;
          });
        } else if (!silent) {
          setState(() {
            _errorMessage =
                'تعذر تحميل خدمات هذا التصنيف حالياً. يرجى التحقق من اتصال الإنترنت وإعادة المحاولة.';
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _onFavoriteToggle(String serviceId) async {
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
      if (mounted) {
        setState(() {
          final index = _services.indexWhere((s) => s.id == serviceId);
          if (index != -1) {
            _services[index] = _services[index].copyWith(
              isFavorite: isNowFav,
            );
          }
        });
      }
      if (_services.any((item) => item.id == serviceId)) {
        final s = _services.firstWhere((item) => item.id == serviceId);
        if (isNowFav) {
          favoritesController.addFavoriteLocally(s.copyWith(isFavorite: true));
        } else {
          favoritesController.removeFavoriteLocally(serviceId);
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          widget.category.title,
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingView(
        message: 'جاري تحميل خدمات ${widget.category.title}...',
      );
    }

    if (_errorMessage != null) {
      return ErrorStateView(
        message: _errorMessage!,
        onRetry: _loadServices,
      );
    }

    if (_services.isEmpty) {
      return EmptyStateView(
        icon: Icons.layers_clear_rounded,
        title: 'لا توجد خدمات متاحة حالياً',
        description:
            'لم يتم العثور على خدمات منشورة في تصنيف "${widget.category.title}".',
        buttonText: 'إعادة المحاولة',
        onButtonPressed: _loadServices,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadServices,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, index) {
          final service = _services[index];
          FavoritesController? favCtrl;
          try {
            favCtrl = context.watch<FavoritesController>();
          } catch (_) {}
          final isFav = (favCtrl != null && favCtrl.isInitialized)
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
              await Navigator.of(context).pushNamed(
                AppRoutes.serviceDetails,
                arguments: service,
              );
              if (!mounted) return;
              try {
                context.read<FavoritesController>().loadFavorites(silent: true);
              } catch (_) {}
            },
            onFavoriteToggle: () => _onFavoriteToggle(service.id),
          );
        },
      ),
    );
  }
}
