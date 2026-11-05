import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
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
                // زر إضافة تقييم جديد في Supabase
                TextButton.icon(
                  onPressed: () {
                    AddReviewBottomSheet.show(
                      context,
                      serviceId: widget.serviceId,
                      serviceTitle: widget.serviceTitle,
                    );
                  },
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECEEF2)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 32,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد تعليقات بعد في قاعدة البيانات.',
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
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
}
