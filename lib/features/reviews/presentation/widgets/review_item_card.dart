import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/review_model.dart';

class ReviewItemCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewItemCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الصورة الرمزية للمستخدم (Avatar)
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: (review.customerAvatar != null &&
                    review.customerAvatar!.trim().isNotEmpty)
                ? NetworkImage(review.customerAvatar!.trim())
                : null,
            child: (review.customerAvatar == null ||
                    review.customerAvatar!.trim().isEmpty)
                ? Text(
                    review.customerName.trim().isNotEmpty
                        ? review.customerName.trim().characters.first
                        : 'م',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // اسم العميل، نص التعليق، وتقييم النجوم الخمس تحت التعليق
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. اسم المستخدم الحقيقي من Supabase
                Text(
                  review.customerName.trim().isNotEmpty
                      ? review.customerName.trim()
                      : 'مستخدم خِدمتي',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),

                // 2. نص التعليق الفعلي من Supabase
                if (review.comment.trim().isNotEmpty)
                  Text(
                    review.comment.trim(),
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 6),

                // 3. نجوم التقييم (5 نجوم: ذهبية حسب التقييم ورمادية للباقي)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (starIndex) => Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: starIndex < review.rating
                          ? const Color(0xFFF59E0B)
                          : AppColors.borderStrong,
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
