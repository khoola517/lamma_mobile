import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';

/// شاشة بوابة المصادقة والشعار (Splash / Auth Gate)
class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({super.key});

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSessionAndNavigate();
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    final authController = context.read<AuthController>();
    // مهلة ملائمة لعرض الشعار بانسيابية أثناء التحقق من الجلسة
    await Future.wait([
      authController.checkAuth(),
      Future.delayed(const Duration(milliseconds: 1200)),
    ]);

    if (!mounted) return;

    if (authController.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.mainNav);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // صورة الشعار بدلاً من كلمة خدمتي بخلفية شفافة وانسيابية
            SizedBox(
              width: 160,
              height: 160,
              child: Image.asset(
                AppAssets.appLogo,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.celebration_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
