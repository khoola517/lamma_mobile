import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../bookings/presentation/controllers/bookings_controller.dart';
import '../controllers/smart_planning_controller.dart';

class PackageCustomizationScreen extends StatefulWidget {
  const PackageCustomizationScreen({super.key});

  @override
  State<PackageCustomizationScreen> createState() =>
      _PackageCustomizationScreenState();
}

class _PackageCustomizationScreenState
    extends State<PackageCustomizationScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SmartPlanningController>();
    final services = controller.customizableServices;
    final total = controller.customPackageTotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: AppColors.primary,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppStrings.customizePackageTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      body: Stack(
        children: [
          // Scrollable List
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
            child: ResponsiveContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instructions & Package Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryVeryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderChipSelected),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.tune_rounded,
                                color: AppColors.primarySoft, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تخصيص باقة الحفل (${controller.selectedPackage?.name ?? "الباقة المختارة"})',
                                style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (controller.savedPackageId != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.green.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        size: 13,
                                        color: Colors.green.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'محفوظة',
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.customizePackageDesc,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Budget Status Indicator Banner
                  Builder(
                    builder: (context) {
                      final budget = controller.request.budget;
                      final isOverBudget = total > budget;
                      final diff = (total - budget).abs();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isOverBudget
                              ? AppColors.errorContainer
                              : AppColors.primaryVeryLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isOverBudget
                                ? AppColors.error
                                : AppColors.primary,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOverBudget
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline_rounded,
                              color: isOverBudget
                                  ? AppColors.error
                                  : AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isOverBudget
                                        ? 'تنبيه: الإجمالي أعلى من الميزانية المحددة'
                                        : 'ضمن نطاق الميزانية المحددة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isOverBudget
                                          ? AppColors.error
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    isOverBudget
                                        ? 'الزيادة الحالية: +${CurrencyFormatter.formatYer(diff)} عن ميزانيتك الأصلية (${CurrencyFormatter.formatYer(budget)})'
                                        : 'المتبقي من ميزانيتك: ${CurrencyFormatter.formatYer(diff)} (الميزانية الأصلية: ${CurrencyFormatter.formatYer(budget)})',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: isOverBudget
                                          ? AppColors.error
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // Service Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = services[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isIncluded
                                ? AppColors.borderDefault
                                : AppColors.borderLight,
                            style: item.isIncluded
                                ? BorderStyle.solid
                                : BorderStyle.solid,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Image or Icon
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: item.imageUrl != null &&
                                        item.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppColors.surfaceSection,
                                          child:
                                              const Icon(Icons.image, size: 24),
                                        ),
                                      )
                                    : Container(
                                        color: AppColors.champagneLight,
                                        child: const Icon(
                                          Icons.celebration_rounded,
                                          color: AppColors.primary,
                                          size: 26,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${item.vendor} · ${item.details}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.formatYer(item.price),
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Toggle Button (+ / Check)
                            GestureDetector(
                              onTap: () {
                                controller.toggleCustomService(item.id);
                                final isNowIncluded = !item.isIncluded;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 1),
                                    content: Text(
                                      isNowIncluded
                                          ? 'تمت إضافة ${item.name} (+${CurrencyFormatter.formatYer(item.price)})'
                                          : 'تم استبعاد ${item.name} (-${CurrencyFormatter.formatYer(item.price)})',
                                      style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    backgroundColor: isNowIncluded
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                );
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: item.isIncluded
                                      ? AppColors.primary
                                      : AppColors.primaryLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.isIncluded
                                      ? Icons.check_rounded
                                      : Icons.add_rounded,
                                  color: item.isIncluded
                                      ? Colors.white
                                      : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Sticky Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    const Border(top: BorderSide(color: AppColors.borderLight)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                            AppStrings.totalCustomPackage,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatYer(total),
                            style: GoogleFonts.cairo(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: CustomButton(
                          text: AppStrings.confirmBooking,
                          //icon: Icons.arrow_back_rounded,
                          isIconTrailing: true,
                          height: 48,
                          isLoading: _isSubmitting ||
                              context.watch<BookingsController>().isLoading,
                          onPressed: _isSubmitting
                              ? null
                              : () async {
                                  final authController =
                                      context.read<AuthController>();
                                  final currentUser =
                                      SupabaseConfig.client.auth.currentUser;
                                  if (!authController.isAuthenticated &&
                                      currentUser == null) {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: AppColors.surfaceCard,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20)),
                                        title: Row(
                                          children: [
                                            const Icon(Icons.lock_outline_rounded,
                                                color: AppColors.primary),
                                            const SizedBox(width: 10),
                                            Text(
                                              'تسجيل الدخول مطلوب',
                                              style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 17),
                                            ),
                                          ],
                                        ),
                                        content: Text(
                                          'لتأكيد حجز الباقة وحفظها في سوبابيز، يرجى تسجيل الدخول إلى حسابك أولاً.',
                                          style: GoogleFonts.cairo(
                                              fontSize: 14, height: 1.5),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(),
                                            child: Text(
                                              'إلغاء',
                                              style: GoogleFonts.cairo(
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10)),
                                            ),
                                            onPressed: () {
                                              Navigator.of(ctx).pop();
                                              Navigator.of(context)
                                                  .pushNamed(AppRoutes.login);
                                            },
                                            child: Text(
                                              'تسجيل الدخول الآن',
                                              style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }

                                  final selectedServiceIds = services
                                      .where((s) => s.isIncluded)
                                      .map((s) => s.id)
                                      .toList();

                                  if (selectedServiceIds.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'يرجى الإبقاء على خدمة واحدة على الأقل لإتمام الحجز.',
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor: AppColors.error,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  if (_isSubmitting) return;
                                  setState(() => _isSubmitting = true);

                                  final bookingsController =
                                      context.read<BookingsController>();

                                  try {
                                    final effectiveUserId = currentUser?.id ??
                                        authController.user?.id;

                                    // حفظ وتحديث تفاصيل الباقة المخصصة في قاعدة البيانات
                                    String? packageUuid =
                                        controller.savedPackageId;
                                    if (effectiveUserId != null) {
                                      try {
                                        packageUuid = await controller
                                            .saveSelectedPackage(
                                                customerId: effectiveUserId);
                                      } catch (_) {}
                                    }

                                    String? packageImageUrl;
                                    String? packageVendor;
                                    final includedServices =
                                        services.where((s) => s.isIncluded).toList();
                                    if (includedServices.isNotEmpty) {
                                      final withImg = includedServices.firstWhere(
                                        (s) =>
                                            s.imageUrl != null &&
                                            s.imageUrl!.isNotEmpty,
                                        orElse: () => includedServices.first,
                                      );
                                      packageImageUrl = withImg.imageUrl;
                                      packageVendor = withImg.vendor;
                                    }

                                    final booking =
                                        await bookingsController.createBooking(
                                      eventType: controller.request.eventType,
                                      eventDate: controller.request.eventDate,
                                      timeSlot: 'الفترة المسائية',
                                      serviceIds: selectedServiceIds,
                                      packageId: packageUuid ??
                                          controller.savedPackageId,
                                      location: controller.request.location,
                                      guestCount:
                                          controller.request.guestsCount,
                                      customerId: effectiveUserId,
                                      budget: total,
                                      notes:
                                          'حجز باقة ${controller.selectedPackage?.name ?? "ذكية"} تشمل ${selectedServiceIds.length} خدمات مخصصة',
                                      serviceImageUrl: packageImageUrl,
                                      vendorName: packageVendor,
                                      category: 'باقة مناسبة',
                                    );

                                    if (context.mounted) {
                                      Navigator.of(context).pushReplacementNamed(
                                        AppRoutes.bookingSuccess,
                                        arguments: booking.bookingCode,
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e
                                                .toString()
                                                .replaceAll('Exception: ', ''),
                                            style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.w600),
                                          ),
                                          backgroundColor: AppColors.error,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isSubmitting = false);
                                    }
                                  }
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
}

