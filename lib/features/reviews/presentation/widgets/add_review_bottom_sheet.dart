import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../controllers/reviews_controller.dart';

class AddReviewBottomSheet extends StatefulWidget {
  final String serviceId;
  final String serviceTitle;
  final String? bookingId;

  const AddReviewBottomSheet({
    super.key,
    required this.serviceId,
    required this.serviceTitle,
    this.bookingId,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String serviceId,
    required String serviceTitle,
    String? bookingId,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddReviewBottomSheet(
        serviceId: serviceId,
        serviceTitle: serviceTitle,
        bookingId: bookingId,
      ),
    );
  }

  @override
  State<AddReviewBottomSheet> createState() => _AddReviewBottomSheetState();
}

class _AddReviewBottomSheetState extends State<AddReviewBottomSheet> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> _ratingLabels = [
    'يحتاج تحسين',
    'مقبول',
    'جيد',
    'جيد جداً',
    'ممتاز ومبهر',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final reviewsController = context.watch<ReviewsController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          'تقييم الخدمة وإضافة رأيك',
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 7,),
                        Text(
                          widget.serviceTitle,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
              Divider(color: AppColors.borderLight, height: 24),

              // Rating Stars Selector
              Center(
                child: Column(
                  children: [
                    Text(
                      'ما هو تقييمك العام للتجربة؟',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starNumber = index + 1;
                        final isFilled = starNumber <= _selectedRating;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRating = starNumber;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: AnimatedScale(
                              scale: isFilled ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isFilled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 25,
                                color: isFilled
                                    ? AppColors.goldYellow
                                    : AppColors.indicatorInactive,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Rating Label Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryVeryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderChipSelected),
                      ),
                      child: Text(
                        _ratingLabels[_selectedRating - 1],
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
              const SizedBox(height: 20),

              // Comment Input
              Text(
                'شاركنا تجربتك بالتفصيل (اختياري)',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText:
                      'اكتب ملاحظاتك عن جودة الخدمة، التعامل، التوقيت، أو أي نصائح تفيد غيرك...',
                  hintStyle: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceWarm,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.borderDefault),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                text: 'نشر التقييم والتعليق',
                isLoading: reviewsController.isSubmitting,
                onPressed: () async {
                  final success = await reviewsController.submitReview(
                    serviceId: widget.serviceId,
                    bookingId: widget.bookingId,
                    rating: _selectedRating,
                    comment: _commentController.text.trim(),
                  );

                  if (context.mounted) {
                    if (success) {
                      Navigator.of(context).pop(true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          content: Text(
                            'شكراً لك! تم إضافة تقييمك وتعليقك بنجاح.',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    } else if (reviewsController.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.error,
                          content: Text(
                            reviewsController.error!,
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
