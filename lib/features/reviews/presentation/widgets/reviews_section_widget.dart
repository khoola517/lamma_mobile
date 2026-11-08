import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../bookings/presentation/controllers/bookings_controller.dart';
import '../controllers/reviews_controller.dart';
import 'add_review_bottom_sheet.dart';
import 'review_item_card.dart';

class ReviewsSectionWidget extends StatefulWidget {
  final String serviceId;
  final String serviceTitle;
  final double initialRating;
  final int initialReviewsCount;

  const ReviewsSectionWidget({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
    required this.initialRating,
    required this.initialReviewsCount,
  });

  @override
  State<ReviewsSectionWidget> createState() => _ReviewsSectionWidgetState();
}

class _ReviewsSectionWidgetState extends State<ReviewsSectionWidget> {
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewsController>().loadServiceReviews(widget.serviceId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReviewsController>();
    final reviews = controller.reviews;
    final count = reviews.isNotEmpty
        ? controller.totalReviewsCount
        : widget.initialReviewsCount;

    final displayedReviews = _showAll ? reviews : reviews.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ترويسة قسم التقييمات وعرض المزيد (مطابقة تماماً لصورة التصميم: Reviews / View More)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'التقييمات',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2538),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                // زر عرض المزيد / عرض أقل إذا كانت التقييمات أكثر من 3 (كما في الصورة View More)
                if (reviews.length > 3)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAll = !_showAll;
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _showAll ? 'عرض أقل' : 'عرض المزيد',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                // زر إضافة تقييم جديد في Supabase (حصرياً لمن قام بحجز الخدمة)
                TextButton.icon(
                  onPressed: _handleAddReviewPressed,
                  icon: const Icon(Icons.add_comment_outlined, size: 14),
                  label: Text(
                    'أضف تقييم',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 14),

        // قائمة بطاقات التقييم الحقيقية من Supabase
        if (controller.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 32,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد تعليقات بعد في قاعدة البيانات.',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () {
                      AddReviewBottomSheet.show(
                        context,
                        serviceId: widget.serviceId,
                        serviceTitle: widget.serviceTitle,
                      );
                    },
                    child: Text(
                      'كن أول من يشارك تجربته',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedReviews.length,
            itemBuilder: (context, index) {
              return ReviewItemCard(review: displayedReviews[index]);
            },
          ),
      ],
    );
  }

  /// معالجة الضغط على زر إضافة تقييم: التحقق الصارم من حجز العميل للخدمة
  Future<void> _handleAddReviewPressed() async {
    // 1. التحقق من تسجيل الدخول
    final authCtrl = context.read<AuthController>();
    if (!authCtrl.isAuthenticated) {
      _showLoginRequiredDialog();
      return;
    }

    // 2. التحقق السريع من الذاكرة (BookingsController)
    final bookingsCtrl = context.read<BookingsController>();
    String? bookingId = bookingsCtrl.getBookingIdForService(widget.serviceId);

    // 3. إذا لم يُعثر على حجز في الذاكرة (مثلاً فتح الخدمة مباشرة)، نفحص السيرفر
    if (bookingId == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );

      try {
        final reviewsCtrl = context.read<ReviewsController>();
        bookingId = await reviewsCtrl.checkUserBookingEligibility(widget.serviceId);
      } catch (_) {
        bookingId = null;
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // إغلاق مؤشر التحقق
      }
    }

    if (!mounted) return;

    // 4. إذا لم يقم المستخدم بحجز هذه الخدمة مسبقاً، نظهر رسالة الشفافية والمصداقية
    if (bookingId == null || bookingId.isEmpty) {
      _showNotBookedDialog();
      return;
    }

    // 5. المستخدم قام بحجز الخدمة بالفعل -> فتح شاشة التقييم وتمرير معرّف الحجز
    AddReviewBottomSheet.show(
      context,
      serviceId: widget.serviceId,
      serviceTitle: widget.serviceTitle,
      bookingId: bookingId,
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'تسجيل الدخول مطلوب',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'يرجى تسجيل الدخول أولاً للتحقق من حجوزاتك وإتاحة إمكانية تقييم الخدمة.',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              if (mounted) {
                Navigator.of(context).pushNamed(AppRoutes.login);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'تسجيل الدخول',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotBookedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandGold.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_outlined,
                color: AppColors.brandGold,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'التقييم للحاجزين فقط',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'عذراً، كتابة التقييمات مخصصة فقط للعملاء الذين قاموا بحجز هذه الخدمة وتجربتها لضمان الشفافية والمصداقية لجميع المستخدمين.',
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: Text(
              'حسناً، فهمت',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
