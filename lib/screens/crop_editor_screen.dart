import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../theme/app_theme.dart';

class CropResult {
  final File croppedFile;
  final File thumbnailFile;
  final double ratio;
  final int width;
  final int height;

  CropResult({
    required this.croppedFile,
    required this.thumbnailFile,
    required this.ratio,
    required this.width,
    required this.height,
  });
}

class CropParams {
  final String imagePath;
  final double scale;
  final double tx;
  final double ty;
  final double cropWidth;
  final double cropHeight;
  final double viewWidth;
  final double viewHeight;
  final double ratio;

  CropParams({
    required this.imagePath,
    required this.scale,
    required this.tx,
    required this.ty,
    required this.cropWidth,
    required this.cropHeight,
    required this.viewWidth,
    required this.viewHeight,
    required this.ratio,
  });
}

class CropEditorScreen extends StatefulWidget {
  final File imageFile;
  final bool isCircle;

  const CropEditorScreen({
    super.key,
    required this.imageFile,
    this.isCircle = false,
  });

  @override
  State<CropEditorScreen> createState() => _CropEditorScreenState();
}

class _CropEditorScreenState extends State<CropEditorScreen> {
  double _selectedRatio = 1.0;
  final TransformationController _transformationController = TransformationController();
  
  bool _isProcessing = false;
  int _imageWidth = 0;
  int _imageHeight = 0;
  bool _dimensionsLoaded = false;

  // Aspect ratio presets
  final List<Map<String, dynamic>> _presets = [
    {'name': '16:9', 'ratio': 16 / 9, 'icon': Icons.crop_16_9_rounded},
    {'name': '1:1', 'ratio': 1.0, 'icon': Icons.crop_square_rounded},
    {'name': '9:16', 'ratio': 9 / 16, 'icon': Icons.crop_portrait_rounded},
  ];

  double _zoomValue = 1.0;

  @override
  void initState() {
    super.initState();
    _loadImageDimensions();
    _transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final matrix = _transformationController.value;
    final scale = matrix.row0.xyz.length;
    if (scale != _zoomValue) {
      setState(() {
        _zoomValue = scale.clamp(1.0, 5.0);
      });
    }
  }

  Future<void> _loadImageDimensions() async {
    debugPrint('[AVATAR_LOG] CropEditorScreen: _loadImageDimensions start');
    try {
      final path = widget.imageFile.path;
      debugPrint('[AVATAR_LOG] CropEditorScreen: loading image dimensions for path: $path');
      final bytes = await widget.imageFile.readAsBytes();
      debugPrint('[AVATAR_LOG] CropEditorScreen: read ${bytes.length} bytes');
      final codec = await ui.instantiateImageCodec(bytes);
      debugPrint('[AVATAR_LOG] CropEditorScreen: native codec created');
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;
      debugPrint('[AVATAR_LOG] CropEditorScreen: native image decoded, size: ${uiImage.width}x${uiImage.height}');
      
      setState(() {
        _imageWidth = uiImage.width;
        _imageHeight = uiImage.height;
        _dimensionsLoaded = true;
        // Auto-select nearest ratio
        _selectedRatio = widget.isCircle ? 1.0 : _getNearestRatio(_imageWidth / _imageHeight);
      });
      
      // Setup initial transformation next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[AVATAR_LOG] CropEditorScreen: post frame callback - resetting transformation');
        _resetTransformation();
      });
    } catch (e, stackTrace) {
      debugPrint('[AVATAR_LOG] CropEditorScreen: Error loading image dimensions: $e');
      debugPrint('[AVATAR_LOG] CropEditorScreen: StackTrace: $stackTrace');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось загрузить изображение: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  double _getNearestRatio(double imageRatio) {
    double minDiff = double.maxFinite;
    double nearest = 1.0;
    for (final preset in _presets) {
      final diff = (imageRatio - (preset['ratio'] as double)).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = preset['ratio'];
      }
    }
    return nearest;
  }

  void _resetTransformation() {
    if (!_dimensionsLoaded) return;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Available height for crop area
    final editAreaHeight = screenHeight * 0.55;

    // Calculate crop box size
    double cropWidth, cropHeight;
    if (_selectedRatio == 1.0) {
      cropWidth = screenWidth - 32;
      cropHeight = cropWidth;
    } else if (_selectedRatio == 16 / 9) {
      cropWidth = screenWidth - 32;
      cropHeight = cropWidth * 9 / 16;
    } else {
      // 9:16
      cropHeight = editAreaHeight - 32;
      cropWidth = cropHeight * 9 / 16;
      if (cropWidth > screenWidth - 32) {
        cropWidth = screenWidth - 32;
        cropHeight = cropWidth * 16 / 9;
      }
    }

    // Calculate initial child view size
    final imageRatio = _imageWidth / _imageHeight;
    final cropRatio = cropWidth / cropHeight;

    double viewWidth, viewHeight;
    if (imageRatio > cropRatio) {
      viewHeight = cropHeight;
      viewWidth = cropHeight * imageRatio;
    } else {
      viewWidth = cropWidth;
      viewHeight = cropWidth / imageRatio;
    }

    // Centering offsets
    final tx0 = (cropWidth - viewWidth) / 2;
    final ty0 = (cropHeight - viewHeight) / 2;

    _transformationController.value = Matrix4.translationValues(tx0, ty0, 0);
    setState(() {});
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _updateZoom(double value) {
    if (!_dimensionsLoaded) return;

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final editAreaHeight = screenHeight * 0.55;

    double cropWidth, cropHeight;
    if (_selectedRatio == 1.0) {
      cropWidth = screenWidth - 32;
      cropHeight = cropWidth;
    } else if (_selectedRatio == 16 / 9) {
      cropWidth = screenWidth - 32;
      cropHeight = cropWidth * 9 / 16;
    } else {
      cropHeight = editAreaHeight - 32;
      cropWidth = cropHeight * 9 / 16;
      if (cropWidth > screenWidth - 32) {
        cropWidth = screenWidth - 32;
        cropHeight = cropWidth * 16 / 9;
      }
    }

    final imageRatio = _imageWidth / _imageHeight;
    final cropRatio = cropWidth / cropHeight;

    double viewWidth, viewHeight;
    if (imageRatio > cropRatio) {
      viewHeight = cropHeight;
      viewWidth = cropHeight * imageRatio;
    } else {
      viewWidth = cropWidth;
      viewHeight = cropWidth / imageRatio;
    }

    final matrix = _transformationController.value;
    final currentScale = matrix.row0.xyz.length;
    final tx = matrix.entry(0, 3);
    final ty = matrix.entry(1, 3);

    final centerX = cropWidth / 2;
    final centerY = cropHeight / 2;

    final childX = (centerX - tx) / currentScale;
    final childY = (centerY - ty) / currentScale;

    double newTx = centerX - childX * value;
    double newTy = centerY - childY * value;

    final maxTx = 0.0;
    final minTx = cropWidth - viewWidth * value;
    final maxTy = 0.0;
    final minTy = cropHeight - viewHeight * value;

    newTx = newTx.clamp(minTx, maxTx);
    newTy = newTy.clamp(minTy, maxTy);

    _transformationController.value = Matrix4.diagonal3Values(value, value, 1.0)
      ..setTranslationRaw(newTx, newTy, 0.0);
    
    setState(() {
      _zoomValue = value;
    });
  }

  Future<void> _saveCrop() async {
    debugPrint('[AVATAR_LOG] CropEditorScreen: _saveCrop start. isProcessing: $_isProcessing, dimensionsLoaded: $_dimensionsLoaded');
    if (_isProcessing || !_dimensionsLoaded) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final mediaQuery = MediaQuery.of(context);
      final screenWidth = mediaQuery.size.width;
      final screenHeight = mediaQuery.size.height;
      final editAreaHeight = screenHeight * 0.55;

      // Crop box dimensions again to match rendering
      double cropWidth, cropHeight;
      if (_selectedRatio == 1.0) {
        cropWidth = screenWidth - 32;
        cropHeight = cropWidth;
      } else if (_selectedRatio == 16 / 9) {
        cropWidth = screenWidth - 32;
        cropHeight = cropWidth * 9 / 16;
      } else {
        cropHeight = editAreaHeight - 32;
        cropWidth = cropHeight * 9 / 16;
        if (cropWidth > screenWidth - 32) {
          cropWidth = screenWidth - 32;
          cropHeight = cropWidth * 16 / 9;
        }
      }

      final imageRatio = _imageWidth / _imageHeight;
      final cropRatio = cropWidth / cropHeight;

      double viewWidth, viewHeight;
      if (imageRatio > cropRatio) {
        viewHeight = cropHeight;
        viewWidth = cropHeight * imageRatio;
      } else {
        viewWidth = cropWidth;
        viewHeight = cropWidth / imageRatio;
      }

      // Extract transformation components
      final matrix = _transformationController.value;
      final scale = matrix.row0.xyz.length; // Get scale factor
      final tx = matrix.entry(0, 3);
      final ty = matrix.entry(1, 3);

      final params = CropParams(
        imagePath: widget.imageFile.path,
        scale: scale,
        tx: tx,
        ty: ty,
        cropWidth: cropWidth,
        cropHeight: cropHeight,
        viewWidth: viewWidth,
        viewHeight: viewHeight,
        ratio: _selectedRatio,
      );

      debugPrint('[AVATAR_LOG] CropEditorScreen: starting compute(_cropImageIsolate) with scale=$scale tx=$tx ty=$ty');
      // Perform crop in separate isolate to keep UI smooth
      final result = await compute(_cropImageIsolate, params);
      debugPrint('[AVATAR_LOG] CropEditorScreen: compute(_cropImageIsolate) finished, result: cropped=${result.croppedFile.path} thumb=${result.thumbnailFile.path}');

      if (mounted) {
        Navigator.pop(context, result);
      }
    } catch (e, stackTrace) {
      debugPrint('[AVATAR_LOG] CropEditorScreen: Error cropping image: $e');
      debugPrint('[AVATAR_LOG] CropEditorScreen: StackTrace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Произошла ошибка при обрезке изображения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Pure Dart isolate processing
  static CropResult _cropImageIsolate(CropParams params) {
    try {
      final file = File(params.imagePath);
      final bytes = file.readAsBytesSync();
      final originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) {
        throw Exception("Could not decode image bytes using image package");
      }

      final orientedImage = img.bakeOrientation(originalImage);
      final originalWidth = orientedImage.width;
      final originalHeight = orientedImage.height;

      // Calculate crop boundaries relative to the child view
      final xStart = -params.tx / params.scale;
      final yStart = -params.ty / params.scale;
      final wCropped = params.cropWidth / params.scale;
      final hCropped = params.cropHeight / params.scale;

      // Map to original coordinates
      final f = originalWidth / params.viewWidth;
      
      final xOrig = xStart * f;
      final yOrig = yStart * f;
      final wOrig = wCropped * f;
      final hOrig = hCropped * f;

      // Safety clamps
      final x = xOrig.round().clamp(0, originalWidth - 1);
      final y = yOrig.round().clamp(0, originalHeight - 1);
      final w = wOrig.round().clamp(1, originalWidth - x);
      final h = hOrig.round().clamp(1, originalHeight - y);

      // Crop image
      final cropped = img.copyCrop(
        orientedImage,
        x: x,
        y: y,
        width: w,
        height: h,
      );

      // Optimized size targets
      int targetW, targetH;
      if (params.ratio == 1.0) {
        targetW = 1080;
        targetH = 1080;
      } else if (params.ratio == 16 / 9) {
        targetW = 1280;
        targetH = 720;
      } else {
        targetW = 720;
        targetH = 1280;
      }

      final optimized = img.copyResize(
        cropped,
        width: targetW,
        height: targetH,
        interpolation: img.Interpolation.cubic,
      );

      // Thumbnail size targets
      int thumbW, thumbH;
      if (params.ratio == 1.0) {
        thumbW = 250;
        thumbH = 250;
      } else if (params.ratio == 16 / 9) {
        thumbW = 320;
        thumbH = 180;
      } else {
        thumbW = 180;
        thumbH = 320;
      }

      final thumbnail = img.copyResize(
        cropped,
        width: thumbW,
        height: thumbH,
        interpolation: img.Interpolation.linear,
      );

      // Encode optimized and thumbnail images as JPEG
      final jpgBytes = img.encodeJpg(optimized, quality: 85);
      final thumbBytes = img.encodeJpg(thumbnail, quality: 70);

      // Save to temp paths
      final systemTemp = Directory.systemTemp;
      final rand = math.Random().nextInt(100000);
      
      final optFile = File('${systemTemp.path}/opt_$rand.jpg')
        ..writeAsBytesSync(jpgBytes);
        
      final thumbFile = File('${systemTemp.path}/thumb_$rand.jpg')
        ..writeAsBytesSync(thumbBytes);

      return CropResult(
        croppedFile: optFile,
        thumbnailFile: thumbFile,
        ratio: params.ratio,
        width: targetW,
        height: targetH,
      );
    } catch (e) {
      print('[AVATAR_LOG_ISOLATE] Exception inside isolate: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    final editAreaHeight = screenHeight * 0.55;

    // Crop box dimensions
    double cropWidth = 0, cropHeight = 0;
    if (_dimensionsLoaded) {
      if (_selectedRatio == 1.0) {
        cropWidth = screenWidth - 32;
        cropHeight = cropWidth;
      } else if (_selectedRatio == 16 / 9) {
        cropWidth = screenWidth - 32;
        cropHeight = cropWidth * 9 / 16;
      } else {
        cropHeight = editAreaHeight - 32;
        cropWidth = cropHeight * 9 / 16;
        if (cropWidth > screenWidth - 32) {
          cropWidth = screenWidth - 32;
          cropHeight = cropWidth * 16 / 9;
        }
      }
    }

    double viewWidth = 0, viewHeight = 0;
    if (_dimensionsLoaded) {
      final imageRatio = _imageWidth / _imageHeight;
      final cropRatio = cropWidth / cropHeight;

      if (imageRatio > cropRatio) {
        viewHeight = cropHeight;
        viewWidth = cropHeight * imageRatio;
      } else {
        viewWidth = cropWidth;
        viewHeight = cropWidth / imageRatio;
      }
    }

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0C0E),
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.primary,
          surface: Color(0xFF161618),
        ),
      ),
      child: Scaffold(
        body: Stack(
          children: [
            // Dark elegant editor workspace
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    // Header Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                          const Text(
                            'Кадрирование',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 48), // Spacer
                        ],
                      ),
                    ),

                    // Editor Workspace
                    Expanded(
                      child: Center(
                        child: _dimensionsLoaded
                            ? SizedBox(
                                width: screenWidth,
                                height: editAreaHeight,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Interactive crop preview
                                    SizedBox(
                                      width: cropWidth,
                                      height: cropHeight,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: InteractiveViewer(
                                          transformationController: _transformationController,
                                          constrained: false,
                                          minScale: 1.0,
                                          maxScale: 5.0,
                                          boundaryMargin: EdgeInsets.zero,
                                          panEnabled: true,
                                          scaleEnabled: true,
                                          child: SizedBox(
                                            width: viewWidth,
                                            height: viewHeight,
                                            child: Image.file(
                                              widget.imageFile,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // Cutout Dimmed background overlay
                                    IgnorePointer(
                                      child: CustomPaint(
                                        size: Size(screenWidth, editAreaHeight),
                                        painter: CutoutPainter(
                                          rect: Rect.fromLTWH(
                                            (screenWidth - cropWidth) / 2,
                                            (editAreaHeight - cropHeight) / 2,
                                            cropWidth,
                                            cropHeight,
                                          ),
                                          isCircle: widget.isCircle,
                                        ),
                                      ),
                                    ),

                                    // Interactive helper grid border
                                    IgnorePointer(
                                      child: Container(
                                        width: cropWidth,
                                        height: cropHeight,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.8),
                                            width: 1.5,
                                          ),
                                          borderRadius: widget.isCircle
                                              ? BorderRadius.circular(cropWidth / 2)
                                              : BorderRadius.circular(4),
                                        ),
                                        child: widget.isCircle
                                            ? const SizedBox.shrink()
                                            : Stack(
                                                children: [
                                                  // Grid lines 1/3 and 2/3
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      VerticalDivider(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                                                      VerticalDivider(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                                                    ],
                                                  ),
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                    children: [
                                                      Divider(color: Colors.white.withValues(alpha: 0.2), height: 1.5),
                                                      Divider(color: Colors.white.withValues(alpha: 0.2), height: 1.5),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                      ),
                    ),

                    // Controls panel
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF141416),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Zoom slider
                          Row(
                            children: [
                              const Icon(Icons.zoom_out_rounded, color: Colors.white54, size: 18),
                              Expanded(
                                child: Slider(
                                  value: _zoomValue,
                                  min: 1.0,
                                  max: 5.0,
                                  activeColor: AppTheme.primary,
                                  inactiveColor: Colors.white10,
                                  onChanged: (val) {
                                    _updateZoom(val);
                                  },
                                ),
                              ),
                              const Icon(Icons.zoom_in_rounded, color: Colors.white54, size: 18),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Presets selectors
                          if (!widget.isCircle) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: _presets.map((preset) {
                                final ratio = preset['ratio'] as double;
                                final isSelected = _selectedRatio == ratio;
                                return GestureDetector(
                                  onTap: () {
                                    if (isSelected) return;
                                    setState(() {
                                      _selectedRatio = ratio;
                                    });
                                    _resetTransformation();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 10),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : Colors.white.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : Colors.white.withValues(alpha: 0.08),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          preset['icon'] as IconData,
                                          size: 18,
                                          color: isSelected ? Colors.white : Colors.white70,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          preset['name'] as String,
                                          style: TextStyle(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? Colors.white : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 36),
                          ] else ...[
                            const SizedBox(height: 24),
                          ],

                          // Save / Cancel buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Отмена',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveCrop,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Применить',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fullscreen loading overlay while saving
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Оптимизация изображения...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Dimmed background overlay painter
class CutoutPainter extends CustomPainter {
  final Rect rect;
  final bool isCircle;

  CutoutPainter({required this.rect, this.isCircle = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF0C0C0E).withValues(alpha: 0.85);

    // Make outer path matching size
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    // Make inner path matching cutout
    final innerPath = Path();
    if (isCircle) {
      innerPath.addOval(rect);
    } else {
      innerPath.addRect(rect);
    }

    // Combine outer and inner with difference winding
    final combined = Path.combine(PathOperation.difference, outerPath, innerPath);

    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
