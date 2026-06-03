import 'dart:ui';
import 'package:flutter/material.dart';

class PostCardImage extends StatefulWidget {
  final String imageUrl;
  final String thumbnailUrl;
  final String imageFormat;

  const PostCardImage({
    super.key,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.imageFormat,
  });

  @override
  State<PostCardImage> createState() => _PostCardImageState();
}

class _PostCardImageState extends State<PostCardImage> {
  bool _fullImageLoaded = false;

  double get _aspectRatio {
    if (widget.imageFormat == '16:9') return 16 / 9;
    if (widget.imageFormat == '9:16') return 9 / 16;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black.withValues(alpha: 0.9),
            pageBuilder: (context, animation, secondaryAnimation) => FullScreenImageViewer(imageUrl: widget.imageUrl),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F22) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Instant blurred low-res thumbnail
                Image.network(
                  widget.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isDark ? const Color(0xFF1E1E20) : const Color(0xFFE5E5EA),
                    child: Icon(
                      Icons.image_outlined,
                      color: isDark ? Colors.white24 : Colors.black26,
                      size: 32,
                    ),
                  ),
                ),

                // Soft blur overlay over the thumbnail during download
                if (!_fullImageLoaded)
                  Positioned.fill(
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.03),
                        ),
                      ),
                    ),
                  ),

                // 2. High-res image lazy-loading on top
                Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) {
                      // Cache hit, render instantly
                      _markFullImageLoaded();
                      return child;
                    }
                    
                    // Trigger state change to clear thumbnail blur when fade-in finishes
                    if (frame != null && !_fullImageLoaded) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_fullImageLoaded) {
                          setState(() {
                            _fullImageLoaded = true;
                          });
                        }
                      });
                    }

                    return AnimatedOpacity(
                      opacity: frame == null ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeIn,
                      child: child,
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _markFullImageLoaded() {
    if (!_fullImageLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_fullImageLoaded) {
          setState(() {
            _fullImageLoaded = true;
          });
        }
      });
    }
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Zoomable Interactive Viewer
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                imageUrl,
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
          ),

          // 2. Floating Close Button
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
        ],
      ),
    );
  }
}
