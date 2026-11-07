import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../home/data/models/service_item_model.dart';
import '../../../home/data/repositories/supabase_services_repository.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../reviews/presentation/widgets/add_review_bottom_sheet.dart';
import '../../data/models/booking_model.dart';
import '../controllers/bookings_controller.dart';

class BookingsListScreen extends StatelessWidget {
  const BookingsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingsController = context.watch<BookingsController>();
    final currentBookings = bookingsController.currentFilteredBookings;
    final selectedTab = bookingsController.selectedTabIndex;

    final tabs = [
      AppStrings.tabAll,
      AppStrings.tabPending,
      AppStrings.tabCompleted
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.bookingsTitle,
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
              // Segmented Tab Filter Bar
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSection,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected = selectedTab == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => bookingsController.setTab(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.surfaceCard
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            tabs[index],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Bookings List
              Expanded(
                child: currentBookings.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: 'لا توجد حجوزات في هذا القسم',
                        description:
                            'تصفح الخدمات واحجز مناسبتك لتظهر تفاصيلها ومتابعتها هنا.',
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => bookingsController.loadBookings(),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: currentBookings.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final booking = currentBookings[index];
                            return _buildBookingCard(
                                context, booking, bookingsController);
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    BookingModel booking,
    BookingsController controller,
  ) {
    Color statusColor;
    Color statusBg;

    switch (booking.status) {
      case BookingStatus.pending:
      case BookingStatus.partiallyAccepted:
        statusColor = AppColors.warning;
        statusBg = AppColors.warningContainer;
        break;
      case BookingStatus.confirmed:
      case BookingStatus.completed:
        statusColor = AppColors.success;
        statusBg = AppColors.successContainer;
        break;
      case BookingStatus.inProgress:
        statusColor = AppColors.brandGold;
        statusBg = AppColors.warningContainer;
        break;
      case BookingStatus.attentionNeeded:
      case BookingStatus.cancelled:
        statusColor = AppColors.error;
        statusBg = AppColors.errorContainer;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Code and Status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined,
                        size: 16, color: AppColors.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      '#${booking.bookingCode}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.statusArabic,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderLight),

          // Main Service Info (Tappable to view service details)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleOpenServiceDetails(context, booking),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: booking.imageUrl.trim().isNotEmpty
                          ? Image.network(
                              booking.imageUrl.trim(),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 72,
                                height: 72,
                                color: AppColors.surfaceSection,
                                child: const Icon(Icons.celebration,
                                    color: AppColors.primarySoft),
                              ),
                            )
                          : Container(
                              width: 72,
                              height: 72,
                              color: AppColors.surfaceSection,
                              child: const Icon(Icons.celebration,
                                  color: AppColors.primarySoft),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.title,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 14, color: AppColors.primarySoft),
                              const SizedBox(width: 6),
                              Text(
                                '${booking.bookingDate.day} / ${booking.bookingDate.month} / ${booking.bookingDate.year}',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 14, color: AppColors.primarySoft),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  booking.timeSlot,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tracking Stepper Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildStepPip(1, 'الطلب', booking.progressStep >= 1),
                _buildStepConnector(booking.progressStep >= 2),
                _buildStepPip(2, 'المراجعة', booking.progressStep >= 2),
                _buildStepConnector(booking.progressStep >= 3),
                _buildStepPip(3, 'التأكيد', booking.progressStep >= 3),
                _buildStepConnector(booking.progressStep >= 4),
                _buildStepPip(4, 'مكتمل', booking.progressStep >= 4),
              ],
            ),
          ),

          // Price & Actions Footer
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceWarm,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المبلغ الإجمالي',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      '${booking.price} ${booking.priceUnit}',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (booking.status == BookingStatus.completed) ...[
                      TextButton.icon(
                        onPressed: () {
                          final serviceId = booking.items.isNotEmpty
                              ? booking.items.first.serviceId
                              : '1';
                          AddReviewBottomSheet.show(
                            context,
                            serviceId: serviceId,
                            serviceTitle: booking.title,
                            bookingId: booking.id,
                          );
                        },
                        icon: const Icon(Icons.star_rounded,
                            size: 15, color: AppColors.brandGold),
                        label: Text(
                          'تقييم',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor:
                              AppColors.primaryLight.withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _handleRebook(context, booking),
                        icon: const Icon(Icons.replay_rounded,
                            size: 15, color: AppColors.primary),
                        label: Text(
                          'إعادة الحجز',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ] else if (booking.status == BookingStatus.pending)
                      TextButton(
                        onPressed: () =>
                            _confirmCancelBooking(context, booking, controller),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'إلغاء الحجز',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      TextButton.icon(
                        onPressed: () => _handleRebook(context, booking),
                        icon: const Icon(Icons.replay_rounded,
                            size: 15, color: AppColors.primary),
                        label: Text(
                          'إعادة الحجز',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<ServiceItemModel> _resolveServiceItem(
      BuildContext context, BookingModel booking) async {
    final serviceId =
        booking.items.isNotEmpty ? booking.items.first.serviceId : null;

    ServiceItemModel? targetService;

    // 1. البحث في الخدمات المحملة بالذاكرة للاستجابة اللحظية
    try {
      final homeCtrl = context.read<HomeController>();
      if (serviceId != null && serviceId.isNotEmpty) {
        targetService = homeCtrl.allServices
            .cast<ServiceItemModel?>()
            .firstWhere((s) => s?.id == serviceId, orElse: () => null);
      }

      if (targetService == null && booking.title.isNotEmpty) {
        targetService = homeCtrl.allServices
            .cast<ServiceItemModel?>()
            .firstWhere(
              (s) =>
                  s?.title.trim().toLowerCase() ==
                  booking.title.trim().toLowerCase(),
              orElse: () => null,
            );
      }
    } catch (_) {}

    // 2. محاولة الجلب من الخادم إذا لم تكن في الذاكرة
    if (targetService == null && serviceId != null && serviceId.isNotEmpty) {
      try {
        targetService =
            await SupabaseServicesRepository().getServiceById(serviceId);
      } catch (_) {}
    }

    // 3. نموذج احتياطي متكامل من تفاصيل الحجز
    targetService ??= ServiceItemModel(
      id: (serviceId != null && serviceId.isNotEmpty)
          ? serviceId
          : booking.id,
      title: booking.title,
      category: booking.category,
      location: booking.vendorName,
      price: booking.price,
      priceUnit: booking.priceUnit,
      rating: 5.0,
      imageUrl: booking.imageUrl,
      description: booking.notes ?? '',
    );

    return targetService;
  }

  Future<void> _handleRebook(
      BuildContext context, BookingModel booking) async {
    final service = await _resolveServiceItem(context, booking);
    if (!context.mounted) return;

    Navigator.of(context).pushNamed(
      AppRoutes.bookingDate,
      arguments: {
        'service': service,
        'initialSlot': booking.timeSlot,
        'initialNotes': booking.notes,
      },
    );
  }

  Future<void> _handleOpenServiceDetails(
      BuildContext context, BookingModel booking) async {
    final service = await _resolveServiceItem(context, booking);
    if (!context.mounted) return;

    Navigator.of(context).pushNamed(
      AppRoutes.serviceDetails,
      arguments: service,
    );
  }

  void _confirmCancelBooking(BuildContext context, BookingModel booking,
      BookingsController controller) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'إلغاء الحجز',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'هل أنت متأكد من رغبتك في إلغاء طلب الحجز #${booking.bookingCode}؟',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'تراجع',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.cancelBooking(booking.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم إلغاء الحجز بنجاح',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: Text(
              'تأكيد الإلغاء',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPip(int step, String label, bool isDone) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primary : AppColors.surfaceSection,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? AppColors.primary : AppColors.borderDefault,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '$step',
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 9,
            fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
            color: isDone ? AppColors.textPrimary : AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? AppColors.primary : AppColors.borderDefault,
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }
}
