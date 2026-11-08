import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? name;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.size = 48,
    this.name,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.onTap,
  });

  /// فك تشفير البيانات سواء كانت Data URI أو Base64 أو رابط عادي
  static ImageProvider? getImageProvider(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final trimmed = url.trim();

    if (trimmed.startsWith('data:image')) {
      try {
        final commaIndex = trimmed.indexOf(',');
        final base64Part = commaIndex != -1 ? trimmed.substring(commaIndex + 1) : trimmed;
        final bytes = base64Decode(base64Part);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return NetworkImage(trimmed);
    }

    // احتمال أن يكون النص Base64 خام بدون ترويسة
    try {
      final bytes = base64Decode(trimmed);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = getImageProvider(imageUrl);
    final effectiveBg = backgroundColor ?? AppColors.primaryLight;

    Widget content;

    if (imageProvider != null) {
      content = Image(
        image: imageProvider,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else {
      content = _buildFallback();
    }

    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        shape: BoxShape.circle,
        border: borderWidth > 0 && borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      child: ClipOval(child: content),
    );

    if (onTap != null) {
      avatarWidget = GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildFallback() {
    if (name != null && name!.trim().isNotEmpty) {
      final initial = name!.trim().characters.first;
      return Center(
        child: Text(
          initial,
          style: GoogleFonts.cairo(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        Icons.person,
        size: size * 0.55,
        color: AppColors.primary,
      ),
    );
  }
}
