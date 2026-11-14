import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../bookings/presentation/controllers/bookings_controller.dart';
import '../controllers/support_controller.dart';
import '../../data/models/complaint_model.dart';
import '../../data/models/complaint_category_model.dart';

class SupportScreen extends StatefulWidget {
  final String? initialBookingId;
  final String? initialBookingCode;

  const SupportScreen({
    super.key,
    this.initialBookingId,
    this.initialBookingCode,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  ComplaintCategoryModel? _selectedCategory;
  String? _selectedBookingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedBookingId = widget.initialBookingId;

    if (widget.initialBookingCode != null) {
      _subjectController.text = 'شكوى بخصوص الحجز #${widget.initialBookingCode}';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<SupportController>();
      controller.loadCategories();
      controller.loadComplaints();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportController = context.watch<SupportController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.primary,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'مركز المساعدة والشكاوى',
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          unselectedLabelStyle: GoogleFonts.cairo(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            const Tab(text: 'تقديم شكوى أو بلاغ'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('بلاغاتي السابقة'),
                  if (supportController.complaints.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${supportController.complaints.length}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNewComplaintTab(context, supportController),
              _buildComplaintsListTab(context, supportController),
            ],
          ),
        ),
      ),
    );
  }

  // 1. New Complaint Form Tab
  Widget _buildNewComplaintTab(
      BuildContext context, SupportController supportController) {
    final bookings = context.watch<BookingsController>().allBookings;
    final categories = supportController.categories.isNotEmpty
        ? supportController.categories
        : ComplaintCategoryModel.defaultFallbackCategories;

    final currentCategory = _selectedCategory != null &&
            categories.any((c) => c.id == _selectedCategory!.id)
        ? categories.firstWhere((c) => c.id == _selectedCategory!.id)
        : categories.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Support Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.headset_mic_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نحن هنا لخدمتك وحل مشكلتك',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'فريق خدمة العملاء متواجد على مدار الساعة لمتابعة بلاغك وضمان حقوقك.',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Complaint Form Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تفاصيل البلاغ أو الشكوى',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 1. Category Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'تصنيف المشكلة',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (supportController.isLoadingCategories)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<ComplaintCategoryModel>(
                    value: currentCategory,
                    isExpanded: true,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _inputDecoration(prefixIcon: Icons.category_outlined),
                    items: categories.map((cat) {
                      return DropdownMenuItem<ComplaintCategoryModel>(
                        value: cat,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                cat.nameAr,
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (cat.requiresBooking)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'يتطلب حجز',
                                  style: GoogleFonts.cairo(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Associated Booking (Optional / Required depending on category)
                  Text(
                    currentCategory.requiresBooking
                        ? 'الحجز المرتبط بالشكوى (مطلوب لهذا التصنيف)'
                        : 'الحجز المرتبط بالشكوى (اختياري)',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: currentCategory.requiresBooking
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    value: _selectedBookingId,
                    isExpanded: true,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: _inputDecoration(
                      prefixIcon: Icons.receipt_long_outlined,
                      hint: 'اختر الحجز إن كان البلاغ يخص طلباً معيناً',
                    ),
                    validator: (val) {
                      if (currentCategory.requiresBooking &&
                          bookings.isNotEmpty &&
                          (val == null || val.isEmpty)) {
                        return 'يرجى تحديد الحجز المتعلق بهذا البلاغ';
                      }
                      return null;
                    },
                    items: [
                      if (!currentCategory.requiresBooking || bookings.isEmpty)
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('بدون تحديد حجز (شكوى عامة)'),
                        ),
                      ...bookings.map((b) {
                        return DropdownMenuItem<String?>(
                          value: b.id,
                          child: Text(
                            '#${b.bookingCode} - ${b.title}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedBookingId = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Subject Input
                  Text(
                    'عنوان الشكوى المختصر',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _subjectController,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(fontSize: 13),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'يرجى كتابة عنوان للشكوى';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      prefixIcon: Icons.title_rounded,
                      hint: 'مثال: تأخر وصول الخدمة، اختلاف المواصفات...',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Description Input
                  Text(
                    'شرح تفاصيل الشكوى والمشكلة',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(fontSize: 13),
                    validator: (val) {
                      if (val == null || val.trim().length < 10) {
                        return 'يرجى كتابة تفاصيل واضحة لا تقل عن 10 أحرف';
                      }
                      return null;
                    },
                    decoration: _inputDecoration(
                      hint:
                          'اشرح بدقة ما حدث معك، وما هو الإجراء أو التعويض المطلوب من إدارة خِدمتي...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  CustomButton(
                    text: 'إرسال الشكوى لفريق المتابعة',
                    isLoading: supportController.isSubmitting,
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final success = await supportController.submitComplaint(
                        bookingId: _selectedBookingId,
                        categoryId: currentCategory.id,
                        subject: _subjectController.text.trim(),
                        category: currentCategory.nameAr,
                        description: _descriptionController.text.trim(),
                      );

                      if (context.mounted) {
                        if (success) {
                          _subjectController.clear();
                          _descriptionController.clear();
                          _tabController.animateTo(1); // switch to history tab
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primary,
                              content: Text(
                                'تم رفع البلاغ بنجاح! سيتم التواصل معك خلال 24 ساعة.',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        } else if (supportController.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.error,
                              content: Text(
                                supportController.error!,
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
        ],
      ),
    );
  }

  // 2. Complaints History Tab
  Widget _buildComplaintsListTab(
      BuildContext context, SupportController supportController) {
    if (supportController.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final complaints = supportController.complaints;

    if (complaints.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد أي شكاوى مسجلة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'سجل الشكاوى فارغ، نتمنى لك دائماً تجارب سعيدة ومريحة مع خِدمتي.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => supportController.loadComplaints(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: complaints.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final complaint = complaints[index];
          return _buildComplaintCard(complaint);
        },
      ),
    );
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: complaint.statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: complaint.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        complaint.statusArabic,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: complaint.statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  complaint.timeAgoArabic,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Category Badge
            if (complaint.category.isNotEmpty && complaint.category != 'عام') ...[
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceWarm,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(
                  complaint.category,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],

            // Subject
            Text(
              complaint.subject,
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),

            if (complaint.bookingCode != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'رقم الحجز: #${complaint.bookingCode}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // Description
            Text(
              complaint.description,
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),

            // Resolution Section (If available)
            if (complaint.resolution != null &&
                complaint.resolution!.trim().isNotEmpty) ...[
              Divider(color: AppColors.borderLight, height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'رد وحل إدارة خِدمتي:',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.resolution!,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({IconData? prefixIcon, String? hint}) {
    return InputDecoration(
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: AppColors.primary, size: 20)
          : null,
      hintText: hint,
      hintStyle: GoogleFonts.cairo(
        fontSize: 12,
        color: AppColors.textTertiary,
      ),
      filled: true,
      fillColor: AppColors.surfaceWarm,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
