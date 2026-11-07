import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import 'di/injection.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class KhadematyApp extends StatelessWidget {
  const KhadematyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: Injection.providers,
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            locale: const Locale('ar', 'YE'),
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              AppColors.setDarkMode(isDark);
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? const SizedBox.shrink(),
              );
            },
            initialRoute: AppRoutes.authGate,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
