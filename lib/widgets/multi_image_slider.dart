import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MultiImageSlider extends StatefulWidget {
  final List<String> imageUrls;
  final double aspectRatio;
  final BorderRadius borderRadius;

  const MultiImageSlider({
    super.key,
    required this.imageUrls,
    this.aspectRatio = 1.0, // Square by default
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  @override
  State<MultiImageSlider> createState() => _MultiImageSliderState();
}

class _MultiImageSliderState extends State<MultiImageSlider> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreenViewer(int initialPage) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        pageBuilder: (context, animation, secondaryAnimation) => SwipableFullScreenImageViewer(
          imageUrls: widget.imageUrls,
          initialPage: initialPage,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // swipable page view
          ClipRRect(
            borderRadius: widget.borderRadius,
            child: Container(
              color: isDark ? const Color(0xFF1F1F22) : const Color(0xFFF2F2F7),
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openFullScreenViewer(index),
                    child: Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary.withValues(alpha: 0.5),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: isDark ? const Color(0xFF1E1E20) : const Color(0xFFE5E5EA),
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: isDark ? Colors.white24 : Colors.black26,
                          size: 36,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Indicator Dots (only if more than 1 image)
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    widget.imageUrls.length,
                    (index) => Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? AppTheme.primary
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SwipableFullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialPage;

  const SwipableFullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialPage,
  });

  @override
  State<SwipableFullScreenImageViewer> createState() => _SwipableFullScreenImageViewerState();
}

class _SwipableFullScreenImageViewerState extends State<SwipableFullScreenImageViewer> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Swipable Interactive Viewer
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white30,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white24,
                    width: 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Page Number / Total Count Indicator
          if (widget.imageUrls.length > 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 22,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12, width: 0.5),
                ),
                child: Text(
                  '${_currentPage + 1} / ${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
