import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = true;

  final RegExp _emailRegex =
      RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final authController = context.read<AuthController>();
    if (authController.status == AuthStatus.loading) return;

    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'يرجى الموافقة على الشروط والأحكام للمتابعة',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // إخفاء لوحة المفاتيح
    FocusScope.of(context).unfocus();

    final result = await authController.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      if (result.requiresEmailConfirmation) {
        // حالة تأكيد البريد الإلكتروني مطلوب في Supabase
        _showEmailConfirmationDialog(
          email: _emailController.text.trim(),
        );
      } else {
        // تم إنشاء جلسة نشطة مباشرة
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message ?? 'تم إنشاء الحساب بنجاح!',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.mainNav);
      }
    } else {
      // إظهار رسالة الخطأ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'تعذر إنشاء الحساب، يرجى المحاولة لاحقاً',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showEmailConfirmationDialog({required String email}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryVeryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تأكيد البريد الإلكتروني',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'تم إنشاء حسابك بنجاح!\n\nأرسلنا رابط تفعيل إلى بريدك الإلكتروني:\n$email\n\nيرجى مراجعة صندوق الوارد (أو الرسائل غير المرغوب فيها) والنقر على رابط التفعيل لتتمكن من تسجيل الدخول.',
            style: GoogleFonts.cairo(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'الانتقال إلى تسجيل الدخول',
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isLoading = authController.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.surfaceWarm,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          AppStrings.registerTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // الشعار أول شيء في الصفحة
                  Center(
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: Image.asset(
                        AppAssets.appLogo,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.celebration_rounded,
                            color: AppColors.primary,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppStrings.registerSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full Name (مطلوب)
                  CustomTextField(
                    label: AppStrings.fullName,
                    hintText: 'مثال: ريم أحمد ',
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    suffixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.fullNameRequired;
                      }
                      if (val.trim().length < 3) {
                        return 'الاسم الكامل يجب أن يحتوي على 3 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email (مطلوب)
                  CustomTextField(
                    label: 'البريد الإلكتروني',
                    hintText: 'example@mail.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    suffixIcon: Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return AppStrings.emailRequired;
                      }
                      if (!_emailRegex.hasMatch(val.trim())) {
                        return AppStrings.invalidEmailFormat;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone Number (اختياري)
                  CustomTextField(
                    label: '${AppStrings.phoneNumber} (اختياري)',
                    hintText: '77xxxxxxx',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    suffixIcon: Icon(
                      Icons.phone_outlined,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password (مطلوب مع زر الإظهار والإخفاء)
                  CustomTextField(
                    label: AppStrings.password,
                    hintText: 'اختر كلمة مرور قوية (6 أحرف فأكثر)',
                    controller: _passwordController,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    // prefixIcon: const Icon(
                    //   Icons.lock_outline_rounded,
                    //   color: AppColors.textTertiary,
                    //   size: 20,
                    // ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'يرجى إدخال كلمة المرور';
                      }
                      if (val.length < 6) {
                        return AppStrings.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password (مطلوب مع زر الإظهار والإخفاء)
                  CustomTextField(
                    label: AppStrings.confirmPassword,
                    hintText: AppStrings.confirmPasswordPlaceholder,
                    controller: _confirmPasswordController,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleRegister(),
                    // prefixIcon: const Icon(
                    //   Icons.lock_clock_outlined,
                    //   color: AppColors.textTertiary,
                    //   size: 20,
                    // ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'يرجى تأكيد كلمة المرور';
                      }
                      if (val != _passwordController.text) {
                        return AppStrings.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Terms Agreement
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreedToTerms,
                          checkColor: Colors.white,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          onChanged: isLoading
                              ? null
                              : (val) {
                                  setState(() {
                                    _agreedToTerms = val ?? true;
                                  });
                                },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'أوافق على الشروط والأحكام وسياسة الخصوصية',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  CustomButton(
                    text: AppStrings.createAccount,
                    //icon: Icons.person_add_alt_1_rounded,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _handleRegister,
                  ),
                  const SizedBox(height: 24),

                  // Return to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.alreadyHaveAccount,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          AppStrings.loginButton,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
