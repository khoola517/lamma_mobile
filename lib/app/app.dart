import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_strings.dart';
import 'di/injection.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

class KhadematyApp extends StatelessWidget {
  const KhadematyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: Injection.providers,
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('ar', 'YE'),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        initialRoute: AppRoutes.authGate,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
