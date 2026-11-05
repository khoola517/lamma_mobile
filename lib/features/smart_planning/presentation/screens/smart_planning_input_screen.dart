import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/custom_button.dart';
import '../controllers/smart_planning_controller.dart';

class SmartPlanningInputScreen extends StatefulWidget {
  const SmartPlanningInputScreen({super.key});

  @override
  State<SmartPlanningInputScreen> createState() =>
      _SmartPlanningInputScreenState();
}

class _SmartPlanningInputScreenState extends State<SmartPlanningInputScreen> {
  final List<String> _eventTypes = [
    'حفلة تخرج',
    'حفل زفاف',
    'حفل خطوبة',
    'عيد ميلاد',
    'مناسبة خاصة'
  ];
  ///final List<String> _locations = ['المكلا', 'صنعاء', 'عدن', 'سيئون'];
  final List<String> _locations = ['المكلا'];

  ///final List<num> _budgetPresets = [400000, 500000, 750000, 1000000];

  late TextEditingController _guestsController;
  late TextEditingController _budgetController;

  @override
  void initState() {
    super.initState();
    _guestsController = TextEditingController();
    _budgetController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SmartPlanningController>().loadCategories();
    });
  }

  @override
  void dispose() {
    _guestsController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final controller = context.read<SmartPlanningController>();
    final guestsText = _guestsController.text.trim();
    final budgetText = _budgetController.text.trim();

    final guests = int.tryParse(guestsText);
    if (guests == null || guests <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى إدخال عدد الأشخاص بشكل صحيح',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final budget = num.tryParse(budgetText);
    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى إدخال الميزانية المتوقعة بشكل صحيح',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    controller.updateGuestsCount(guests);
    controller.updateBudget(budget);

    final success = await controller.generatePlan();
    if (mounted) {
      if (success) {
        Navigator.of(context).pushNamed(AppRoutes.smartPlanResult);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'تعذر إنشاء الخطة الذكية، يرجى التحقق من المدخلات.',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SmartPlanningController>();
    final request = controller.request;
    final isLoading = controller.status == SmartPlanStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: AppColors.primary,),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'التخطيط الذكي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        //actions: [
        //   IconButton(
        //     icon: const Icon(Icons.info_outline_rounded,
        //         color: AppColors.textSecondary),
        //     onPressed: () {
        //       showDialog(
        //         context: context,
        //         builder: (ctx) => AlertDialog(
        //           backgroundColor: AppColors.surfaceCard,
        //           shape: RoundedRectangleBorder(
        //               borderRadius: BorderRadius.circular(16)),
        //           title: Row(
        //             children: [
        //               const Icon(Icons.auto_awesome, color: AppColors.primary),
        //               const SizedBox(width: 8),
        //               Text(
        //                 'عن التخطيط الذكي',
        //                 style: GoogleFonts.cairo(
        //                     fontWeight: FontWeight.w800, fontSize: 16),
        //               ),
        //             ],
        //           ),
        //           content: Text(
        //             'يقوم النظام الذكي بالربط المباشر مع قاعدة بيانات سوبابيز لتحليل ميزانيتك ومقارنة مقدمي الخدمات المتاحين وحجز باقة متكاملة تلقائياً بأفضل سعر.',
        //             style: GoogleFonts.cairo(fontSize: 13, height: 1.6),
        //           ),
        //           actions: [
        //             TextButton(
        //               onPressed: () => Navigator.of(ctx).pop(),
        //               child: Text('حسناً',
        //                   style: GoogleFonts.cairo(
        //                       fontWeight: FontWeight.w700,
        //                       color: AppColors.primary)),
        //             ),
        //           ],
        //         ),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Titles
                Center(
                  child: Column(
                    children: [
                      Text(
                        AppStrings.smartPlannerTitle,
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.smartPlannerSubtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Field 1: Event Type
                _buildFieldLabel(AppStrings.eventType),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: request.eventType,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary),
                      items: _eventTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              // const Icon(Icons.celebration_outlined,
                              //     size: 18, color: AppColors.primarySoft),
                              // const SizedBox(width: 10),
                              Text(
                                type,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.updateEventType(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Field 2: Number of Guests
                _buildFieldLabel(AppStrings.guestsCount),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: TextField(
                    controller: _guestsController,
                    keyboardType: TextInputType.number,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'أدخل عدد الأشخاص (مثال: 100)',
                      hintStyle: GoogleFonts.cairo(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      suffixIcon: const Icon(Icons.group_outlined,
                          color: AppColors.primarySoft, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Field 3: Budget
                _buildFieldLabel(AppStrings.budget),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.currency,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.champagneDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.cairo(
                              fontSize: 14, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'الميزانية المتوقعة بالريال (مثال: 500,000)',
                            hintStyle: GoogleFonts.cairo(
                              fontSize: 13,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            suffixIcon: const Icon(Icons.payments_outlined,
                                color: AppColors.primarySoft, size: 20),
                          ),
                          onChanged: (val) {
                            final parsed = num.tryParse(val);
                            if (parsed != null) controller.updateBudget(parsed);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Budget Presets
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: Row(
                //     children:
                //      _budgetPresets.map((preset) {
                //       final isSelected = request.budget == preset;
                //       return GestureDetector(
                //         onTap: () {
                //           _budgetController.text = preset.toInt().toString();
                //           controller.updateBudget(preset);
                //         },
                //         child: Container(
                //           margin: const EdgeInsets.only(left: 8),
                //           padding: const EdgeInsets.symmetric(
                //               horizontal: 12, vertical: 6),
                //           decoration: BoxDecoration(
                //             color: isSelected
                //                 ? AppColors.primaryLight
                //                 : AppColors.surfaceCard,
                //             borderRadius: BorderRadius.circular(20),
                //             border: Border.all(
                //               color: isSelected
                //                   ? AppColors.primary
                //                   : AppColors.borderLight,
                //             ),
                //           ),
                //           child: Text(
                //             CurrencyFormatter.formatYer(preset),
                //             style: GoogleFonts.cairo(
                //               fontSize: 11,
                //               fontWeight: isSelected
                //                   ? FontWeight.w700
                //                   : FontWeight.w500,
                //               color: isSelected
                //                   ? AppColors.primary
                //                   : AppColors.textSecondary,
                //             ),
                //           ),
                //         ),
                //       );
                //     }).toList(),
                //   ),
                // ),
                const SizedBox(height: 16),

                // Field 4: Location
                _buildFieldLabel(AppStrings.location),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDefault),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: request.location,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary),
                      items: _locations.map((loc) {
                        return DropdownMenuItem(
                          value: loc,
                          child: Row(
                            children: [
                              // const Icon(Icons.location_on_outlined,
                              //     size: 18, color: AppColors.primarySoft),
                              // const SizedBox(width: 10),
                              Text(
                                loc,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.updateLocation(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Field 5: Event Date
                _buildFieldLabel(AppStrings.eventDate),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: request.eventDate.isAfter(DateTime.now())
                          ? request.eventDate
                          : DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) controller.updateDate(picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // const Icon(Icons.calendar_today_rounded,
                            //     size: 18, color: AppColors.primarySoft),
                            // const SizedBox(width: 10),
                            Text(
                              '${request.eventDate.day} / ${request.eventDate.month} / ${request.eventDate.year}',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.calendar_today_rounded,
                                size: 18, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Field 6: Categories from Supabase
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel(AppStrings.optionalServices),
                    if (request.requestedServices.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          for (final s in List.from(request.requestedServices)) {
                            controller.toggleRequestedService(s);
                          }
                        },
                        child: Text(
                          'اختيار الكل',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                if (controller.isLoadingCategories)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.categories.map((cat) {
                      final isSelected = request.requestedServices
                              .contains(cat.id) ||
                          request.requestedServices.contains(cat.title);
                      return GestureDetector(
                        onTap: () =>
                            controller.toggleRequestedService(cat.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cat.title,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_rounded,
                                    size: 14, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 28),

                // Submit Button
                CustomButton(
                  text: AppStrings.generatePlanButton,
                  //icon: Icons.auto_awesome,
                  isLoading: isLoading,
                  onPressed: _handleSubmit,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
