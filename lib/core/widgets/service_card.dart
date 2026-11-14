import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class ServiceCard extends StatefulWidget {
  final String title;
  final String location;
  final String priceText;
  final double rating;
  final String imageUrl;
  final List<String> images;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final double width;

  const ServiceCard({
    super.key,
    required this.title,
    required this.location,
    required this.priceText,
    required this.rating,
    required this.imageUrl,
    this.images = const [],
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteToggle,
    this.width = 285.0,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  List<String> get _effectiveImages {
    final list = <String>[];
    if (widget.imageUrl.trim().isNotEmpty) {
      list.add(widget.imageUrl.trim());
    }
    for (final img in widget.images) {
      final trimmed = img.trim();
      if (trimmed.isNotEmpty && !list.contains(trimmed)) {
        list.add(trimmed);
      }
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant ServiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentImageIndex >= _effectiveImages.length && _effectiveImages.isNotEmpty) {
      _currentImageIndex = 0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    final list = _effectiveImages;
    if (list.length <= 1) return;
    final prev = (_currentImageIndex - 1 + list.length) % list.length;
    _pageController.animateToPage(
      prev,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _goToNext() {
    final list = _effectiveImages;
    if (list.length <= 1) return;
    final next = (_currentImageIndex + 1) % list.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    } else if (url.startsWith('data:image')) {
      try {
        final comma = url.indexOf(',');
        final b64 = comma != -1 ? url.substring(comma + 1) : url;
        return Image.memory(
          base64Decode(b64),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      } catch (_) {
        return _placeholder();
      }
    } else if (url.isNotEmpty) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    } else {
      return _placeholder();
    }
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceSection,
      child: Icon(
        Icons.image_outlined,
        size: 40,
        color: AppColors.textTertiary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagesList = _effectiveImages;

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image container with overlay actions
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 170,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // عرض الصور في PageView لدعم السحب والتنقل
                      if (imagesList.isNotEmpty)
                        PageView.builder(
                          controller: _pageController,
                          itemCount: imagesList.length,
                          onPageChanged: (idx) {
                            setState(() => _currentImageIndex = idx);
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: widget.onTap,
                              child: _buildImage(imagesList[index]),
                            );
                          },
                        )
                      else
                        _placeholder(),

                      // تدرج علوي لتوضيح أيقونة المفضلة
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // زر الإضافة / الحذف من المفضلة
                      Positioned(
                        top: 10,
                        left: 10,
                        child: GestureDetector(
                          onTap: widget.onFavoriteToggle,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: widget.isFavorite
                                  ? Colors.redAccent
                                  : Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // أزرار التنقل بين الصور (تظهر فقط عند وجود أكثر من صورة)
                      if (imagesList.length > 1)
                        Positioned(
                          left: 6,
                          right: 6,
                          top: 0,
                          bottom: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // زر الانتقال للصورة السابقة (يسار)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _goToPrevious,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                              // زر الانتقال للصورة التالية (يمين)
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _goToNext,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.45),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // مؤشرات النقاط لعدد الصور في الأسفل
                      if (imagesList.length > 1)
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imagesList.length,
                              (index) => GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                  width: _currentImageIndex == index ? 16 : 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.35),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Content details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: AppColors.goldYellow,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              widget.rating > 0
                                  ? widget.rating.toStringAsFixed(1)
                                  : 'جديد',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.location,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.borderLight),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'السعر',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            widget.priceText,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
