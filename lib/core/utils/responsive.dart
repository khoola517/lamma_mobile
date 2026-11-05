import 'package:flutter/material.dart';

/// Reusable Responsive utility class to ensure adaptive layouts across all screen sizes
/// Mobile, Tablet, and Desktop according to design requirements.
class Responsive {
  final BuildContext context;
  late final MediaQueryData _mediaQuery;

  Responsive(this.context) {
    _mediaQuery = MediaQuery.of(context);
  }

  static Responsive of(BuildContext context) => Responsive(context);

  double get width => _mediaQuery.size.width;
  double get height => _mediaQuery.size.height;
  Orientation get orientation => _mediaQuery.orientation;
  double get devicePixelRatio => _mediaQuery.devicePixelRatio;
  EdgeInsets get padding => _mediaQuery.padding;

  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  bool get isMobile => width < mobileBreakpoint;
  bool get isTablet => width >= mobileBreakpoint && width < desktopBreakpoint;
  bool get isDesktop => width >= desktopBreakpoint;
  bool get isLandscape => orientation == Orientation.landscape;

  /// Returns appropriate value based on screen size
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  /// Responsive padding
  EdgeInsets get screenPadding {
    if (isDesktop) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    }
    if (isTablet) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  /// Maximum content constraint for wide screens (keeps mobile layout elegant on tablet/desktop)
  double get maxContentWidth => 480.0;

  /// Scaled size based on reference mobile viewport (390 width)
  double w(double size) {
    if (width > 600) return size; // Don't oversaturate on large screens
    return (width / 390.0) * size;
  }

  /// Scaled font size based on text scale factor and screen
  double sp(double fontSize) {
    final scale = (width / 390.0).clamp(0.85, 1.15);
    return fontSize * scale;
  }

  /// Adaptive grid cross axis count
  int get gridColumns {
    if (isDesktop) return 4;
    if (isTablet) return 3;
    return 2;
  }
}

/// Extension on BuildContext for quick access to Responsive helpers
extension ResponsiveContextExtension on BuildContext {
  Responsive get responsive => Responsive.of(this);
  bool get isMobile => responsive.isMobile;
  bool get isTablet => responsive.isTablet;
  bool get isDesktop => responsive.isDesktop;
  double get screenWidth => responsive.width;
  double get screenHeight => responsive.height;
}

/// Reusable Widget that bounds content to a responsive max width for tablets & web
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? context.responsive.maxContentWidth;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Responsive Builder Widget for rendering different widgets depending on form factor
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final resp = Responsive.of(context);
    if (resp.isDesktop && desktop != null) return desktop!;
    if (resp.isTablet && tablet != null) return tablet!;
    return mobile;
  }
}
