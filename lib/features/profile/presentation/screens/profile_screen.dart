import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/theme_controller.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/edit_profile_dialog.dart';

class ProfileScreen extends StatelessWidget {
  final void Function(int tabIndex)? onNavigateTab;

  const ProfileScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final themeController = context.watch<ThemeController>();
    final user = authController.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.profileTitle,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Profile Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => EditProfileDialog.show(context, user),
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.primaryLight, width: 2.5),
                              ),
                              child: AppAvatar(
                                imageUrl: user?.avatarUrl,
                                size: 64,
                                name: user?.name,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  (user?.name.isNotEmpty == true)
                                      ? user!.name
                                      : 'مستخدم خِدمتي',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                            if (user?.phone.isNotEmpty == true)
                              Text(
                                user!.phone,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            if (user?.email.isNotEmpty == true)
                              Text(
                                user!.email,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => EditProfileDialog.show(context, user),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSection,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Section 1: Account Settings
                _buildSectionHeader('إعدادات الحساب'),
                _buildMenuContainer([
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'حجوزاتي ومناسباتي',
                    subtitle: 'متابعة وتفاصيل الحجوزات السابقة والحالية',
                    onTap: () {
                      if (onNavigateTab != null) onNavigateTab!(3);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'الإشعارات والتنبيهات',
                    subtitle: 'إدارة التنبيهات والعروض الخاصة',
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.notifications);
                    },
                  ),
                  _buildThemeSettingItem(context, themeController),
                ]),
                const SizedBox(height: 20),

                // Section 2: Preferences & App
                _buildSectionHeader('التفضيلات والتطبيق'),
                _buildMenuContainer([
                  _buildMenuItem(
                    icon: Icons.favorite_border_rounded,
                    title: 'المفضلة',
                    subtitle: 'القاعات والخدمات المحفوظة',
                    onTap: () {
                      if (onNavigateTab != null) onNavigateTab!(2);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.language_rounded,
                    title: 'اللغة',
                    trailingText: 'العربية',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'الشروط والأحكام وسياسة الخصوصية',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.headset_mic_outlined,
                    title: 'المساعدة والشكاوى',
                    subtitle: 'رفع البلاغات ومتابعة الشكاوى وخدمة العملاء',
                    onTap: () {
                      Navigator.of(context).pushNamed(AppRoutes.support);
                    },
                  ),
                ]),
                const SizedBox(height: 24),

                // Logout Action
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: ListTile(
                    // contentPadding:
                    //     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    // leading: Container(
                    //   width: 40,
                    //   height: 40,
                    //   decoration: BoxDecoration(
                    //     color: AppColors.error.withOpacity(0.1),
                    //     shape: BoxShape.circle,
                    //   ),
                    //   child: const Icon(Icons.logout_rounded,
                    //       color: AppColors.error, size: 20),
                    // ),
                    title: Text(
                      AppStrings.logout,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_left_rounded,
                        color: AppColors.error, size: 20),
                    onTap: () {
                      _showLogoutDialog(context, authController);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMenuContainer(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primaryVeryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: trailingText != null
          ? Text(
              trailingText,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            )
          : Icon(Icons.chevron_left_rounded,
              color: AppColors.textTertiary, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildThemeSettingItem(
    BuildContext context,
    ThemeController themeController,
  ) {
    final isDark = themeController.isDarkMode;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF332900) : AppColors.primaryVeryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        'المظهر (الوضع الليلي)',
        style: GoogleFonts.cairo(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        themeController.themeModeName,
        style: GoogleFonts.cairo(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch.adaptive(
            value: isDark,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primaryDark,
            onChanged: (val) {
              themeController.toggleDarkMode(val);
            },
          ),
          Icon(
            Icons.chevron_left_rounded,
            color: AppColors.textTertiary,
            size: 18,
          ),
        ],
      ),
      onTap: () => _showThemeModeSelectionDialog(context, themeController),
    );
  }

  void _showThemeModeSelectionDialog(
    BuildContext context,
    ThemeController themeController,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'اختيار مظهر التطبيق',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'اختر المظهر المفضل لديك، وسيتم حفظ اختيارك تلقائياً',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildThemeOptionTile(
                  context: ctx,
                  themeController: themeController,
                  mode: ThemeMode.light,
                  icon: Icons.light_mode_rounded,
                  title: 'الوضع الفاتح (النهاري)',
                  subtitle: 'ألوان ساطعة وتصميم مشرق ومريح للعين نهاراً',
                ),
                const SizedBox(height: 10),
                _buildThemeOptionTile(
                  context: ctx,
                  themeController: themeController,
                  mode: ThemeMode.dark,
                  icon: Icons.dark_mode_rounded,
                  title: 'الوضع الداكن (الليلي)',
                  subtitle: 'خلفيات داكنة تقلل إجهاد العين وتحافظ على البطارية',
                ),
                const SizedBox(height: 10),
                _buildThemeOptionTile(
                  context: ctx,
                  themeController: themeController,
                  mode: ThemeMode.system,
                  icon: Icons.settings_brightness_rounded,
                  title: 'تلقائي (حسب نظام الجهاز)',
                  subtitle: 'يتوافق تلقائياً مع مظهر الهاتف العام',
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionTile({
    required BuildContext context,
    required ThemeController themeController,
    required ThemeMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = themeController.themeMode == mode;
    return InkWell(
      onTap: () {
        themeController.setThemeMode(mode);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (themeController.isDarkMode
                  ? const Color(0xFF332900)
                  : AppColors.primaryLight.withOpacity(0.5))
              : AppColors.surfaceSection,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : AppColors.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              )
            else
              Icon(
                Icons.radio_button_unchecked_rounded,
                color: AppColors.borderStrong,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'تسجيل الخروج',
            style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
            style: GoogleFonts.cairo(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                await authController.logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(
                'تأكيد الخروج',
                style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
