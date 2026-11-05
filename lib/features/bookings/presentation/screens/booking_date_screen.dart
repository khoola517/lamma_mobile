import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/data/models/service_item_model.dart';
import '../controllers/bookings_controller.dart';

class BookingDateScreen extends StatefulWidget {
  final ServiceItemModel? service;

  const BookingDateScreen({super.key, this.service});

  @override
  State<BookingDateScreen> createState() => _BookingDateScreenState();
}

class _BookingDateScreenState extends State<BookingDateScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _selectedSlot = 'الفترة المسائية (4:00 م - 11:00 م)';
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _slots = [
    'الفترة المسائية (4:00 م - 11:00 م)',
    'الفترة الصباحية (9:00 ص - 2:00 م)',
    'يوم كامل',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _submitBooking() async {
    final service = widget.service;
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى اختيار خدمة صالحة لإتمام الحجز.',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authController = context.read<AuthController>();
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (!authController.isAuthenticated && currentUser == null) {
      _showLoginPromptDialog();
      return;
    }

    final bookingsController = context.read<BookingsController>();

    setState(() => _isSubmitting = true);

    try {
      final newBooking = await bookingsController.createBooking(
        eventType: service.title,
        eventDate: _selectedDate,
        timeSlot: _selectedSlot,
        serviceIds: [service.id],
        customerId: currentUser?.id ?? authController.user?.id,
        location: service.location,
        budget: service.price,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        serviceImageUrl: service.imageUrl,
        category: service.category,
      );

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.bookingSuccess,
          arguments: newBooking.bookingCode,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
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
  }

  void _showLoginPromptDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              'تسجيل الدخول مطلوب',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        content: Text(
          'لتأكيد طلب الحجز ومزامنته مع سوبابيز، يرجى تسجيل الدخول إلى حسابك أولاً.',
          style: GoogleFonts.cairo(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'إلغاء',
              style: GoogleFonts.cairo(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed(AppRoutes.login);
            },
            child: Text(
              'تسجيل الدخول الآن',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: AppColors.primary,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'تأكيد الحجز',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Service Summary Card
                if (service != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      //border: Border.all(color: AppColors.primary),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            service.imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: AppColors.surfaceSection),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.title,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                service.location,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                service.formattedPrice,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Date Selection
                Text(
                  'حدد موعد المناسبة',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _selectedDate.isBefore(now) ? now : _selectedDate,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                           
                            Text(
                              '${_selectedDate.day} / ${_selectedDate.month} / ${_selectedDate.year}',
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                         const Icon(Icons.calendar_month_rounded,
                                color: AppColors.primary, size: 22),
                            const SizedBox(width: 10),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Time Slot Selection
                Text(
                  'الفترة والتوقيت',
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: _slots.map((slot) {
                    final isSelected = slot == _selectedSlot;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSlot = slot),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight
                              : AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderDefault,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              slot,
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Notes / Special requirements
                CustomTextField(
                  label: 'ملاحظات أو متطلبات خاصة',
                  hintText: 'اكتب أي تفاصيل ترغب في إعلام مقدم الخدمة بها...',
                  controller: _notesController,
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Payment Method
                // Text(
                //   'طريقة الدفع المفضلة',
                //   style: GoogleFonts.cairo(
                //     fontSize: 15,
                //     fontWeight: FontWeight.w800,
                //     color: AppColors.textPrimary,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 16),
                //   decoration: BoxDecoration(
                //     color: AppColors.surfaceCard,
                //     borderRadius: BorderRadius.circular(12),
                //     border: Border.all(color: AppColors.borderDefault),
                //   ),
                //   child: DropdownButtonHideUnderline(
                //     child: DropdownButton<String>(
                //       value: _selectedPayment,
                //       isExpanded: true,
                //       items: [
                //         'الدفع عند التأكيد',
                //         'تحويل بنكي / محفظة كاش',
                //         'بطاقة فيزا / ماستركارد'
                //       ].map((m) {
                //         return DropdownMenuItem(
                //           value: m,
                //           child: Text(
                //             m,
                //             style: GoogleFonts.cairo(
                //                 fontSize: 13, fontWeight: FontWeight.w600),
                //           ),
                //         );
                //       }).toList(),
                //       onChanged: (val) {
                //         if (val != null) setState(() => _selectedPayment = val);
                //       },
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 28),

                // Confirm and Submit Button
                CustomButton(
                  text: AppStrings.confirmBooking,
                  //icon: Icons.check_circle_outline_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submitBooking,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
