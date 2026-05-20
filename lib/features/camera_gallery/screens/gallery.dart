import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image/image.dart' as img;
import 'package:padizdoctor/features/camera_gallery/screens/image_preview.dart';
import 'package:padizdoctor/features/camera_gallery/screens/upload_loading.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../services/gallery_service.dart';

class GalleryPicker extends StatefulWidget {
  const GalleryPicker({super.key});

  @override
  State<GalleryPicker> createState() => _GalleryPickerState();
}

class _GalleryPickerState extends State<GalleryPicker> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  final cameras = GetIt.instance<List<CameraDescription>>();
  
  bool _isDetecting = false;
  bool _isTakingPicture = false;
  String _guidanceMessage = "Place ONE paddy leaf inside the box";
  Color _frameColor = Colors.white;
  DateTime? _steadyStartTime;
  bool _isReadyToCapture = false;

  static const double _frameSize = 280.0;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      cameras[0], 
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );
    _initializeControllerFuture = controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _startDetectionStream();
    }).catchError((Object e) {
      if (e is CameraException) {
        // Handle exception
      }
    });
  }

  void _startDetectionStream() {
    if (!controller.value.isStreamingImages) {
      controller.startImageStream((CameraImage image) {
        if (_isDetecting || _isTakingPicture) return;
        _isDetecting = true;
        _processCameraImage(image);
      });
    }
  }

  void _processCameraImage(CameraImage image) {
    try {
      int greenCount = 0;
      int totalCount = 0;

      final int width = image.width;
      final int height = image.height;
      
      // Sample a central square representing the detection frame
      final int boxSize = (math.min(width, height) * 0.5).toInt();
      final int startX = (width - boxSize) ~/ 2;
      final int startY = (height - boxSize) ~/ 2;

      if (image.format.group == ImageFormatGroup.yuv420) {
        final int uvRowStride = image.planes[1].bytesPerRow;
        final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

        for (int y = startY; y < startY + boxSize; y += 10) {
          for (int x = startX; x < startX + boxSize; x += 10) {
            final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
            if (uvIndex < image.planes[1].bytes.length && uvIndex < image.planes[2].bytes.length) {
              final int u = image.planes[1].bytes[uvIndex];
              final int v = image.planes[2].bytes[uvIndex];
              // YCbCr: green typically has low Cb (U) and low Cr (V)
              if (u < 115 && v < 115) {
                greenCount++;
              }
              totalCount++;
            }
          }
        }
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        final int rowStride = image.planes[0].bytesPerRow;
        for (int y = startY; y < startY + boxSize; y += 10) {
          for (int x = startX; x < startX + boxSize; x += 10) {
            final int index = y * rowStride + x * 4;
            if (index + 2 < image.planes[0].bytes.length) {
              final int b = image.planes[0].bytes[index];
              final int g = image.planes[0].bytes[index + 1];
              final int r = image.planes[0].bytes[index + 2];
              if (g > r + 10 && g > b + 10 && g > 60) {
                greenCount++;
              }
              totalCount++;
            }
          }
        }
      }

      if (totalCount > 0 && (greenCount / totalCount) > 0.15) {
        if (_steadyStartTime == null) {
          _steadyStartTime = DateTime.now();
        }
        final duration = DateTime.now().difference(_steadyStartTime!);
        
        if (duration.inMilliseconds > 2000) {
          if (mounted) {
            setState(() {
              _guidanceMessage = "Ready to capture!";
              _frameColor = Colors.greenAccent;
              _isReadyToCapture = true;
            });
          }
        } else if (duration.inMilliseconds > 500) {
          if (mounted) {
            setState(() {
              _guidanceMessage = "Hold steady...";
              _frameColor = Colors.orangeAccent;
              _isReadyToCapture = false;
            });
          }
        }
      } else {
        _steadyStartTime = null;
        if (mounted) {
          setState(() {
            _guidanceMessage = "Place ONE paddy leaf inside the box";
            _frameColor = Colors.white;
            _isReadyToCapture = false;
          });
        }
      }
    } catch (e) {
      // ignore
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _takePicture() async {
    if (_isTakingPicture) return;
    setState(() {
      _isTakingPicture = true;
    });

    // Show a brief loading indicator immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
    );

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }
      
      final XFile imageFile = await controller.takePicture();
      if (!mounted) return;

      final File originalFile = File(imageFile.path);
      
      // Perform background cropping
      final Size screenSize = MediaQuery.of(context).size;
      final croppedPath = await _cropToFrameBounds(originalFile, screenSize);
      final file = File(croppedPath);

      final result = PlatformFile(
        name: file.path.split('/').last,
        path: file.path,
        size: file.lengthSync(),
      );

      if (mounted) {
        Navigator.pop(context); // remove loading dialog
      }

      await _runImageQualityCheck(result);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // remove loading dialog
      }
      _isTakingPicture = false;
      if (mounted && controller.value.isInitialized && ModalRoute.of(context)?.isCurrent == true) {
        _startDetectionStream(); // restart stream on failure
      }
    }
  }

  Future<String> _cropToFrameBounds(File imageFile, Size screenSize) async {
    final bytes = await imageFile.readAsBytes();
    img.Image? decodedImage = img.decodeImage(bytes);
    
    if (decodedImage == null) return imageFile.path;

    int imageWidth = decodedImage.width;
    int imageHeight = decodedImage.height;

    // Calculate scale used by BoxFit.cover
    double scale = math.max(screenSize.width / imageWidth, screenSize.height / imageHeight);

    // Calculate the crop size in image pixels
    int cropSize = (_frameSize / scale).toInt();

    // The frame has a Y offset of -50 on the screen
    double yOffsetScreen = -50.0;
    int yOffsetImage = (yOffsetScreen / scale).toInt();

    final int startX = (imageWidth - cropSize) ~/ 2;
    final int startY = (imageHeight - cropSize) ~/ 2 + yOffsetImage;

    // Ensure we don't go out of bounds
    int safeStartX = startX.clamp(0, math.max(0, imageWidth - cropSize));
    int safeStartY = startY.clamp(0, math.max(0, imageHeight - cropSize));

    img.Image cropped = img.copyCrop(
      decodedImage, 
      x: safeStartX, 
      y: safeStartY, 
      width: cropSize, 
      height: cropSize
    );

    final tmpDir = await getTemporaryDirectory();
    final destPath = p.join(tmpDir.path, 'cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final croppedFile = File(destPath);
    await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 90));
    
    return destPath;
  }

  @override
  void dispose() {
    if (controller.value.isStreamingImages) {
      controller.stopImageStream();
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
      );
    }
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Layer 1: The Camera Feed
            Positioned.fill(
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.previewSize!.height,
                      height: controller.value.previewSize!.width,
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
              ),
            ),

            // Layer 2: Transparent Overlay with Cut-out Frame
            Positioned.fill(
              child: CustomPaint(
                painter: OverlayPainter(
                  frameSize: _frameSize,
                  frameColor: _frameColor,
                  yOffset: -50, // Positioned slightly higher
                ),
              ),
            ),

            // Layer 3: Dynamic Guidance Message
            Positioned(
              top: MediaQuery.of(context).size.height / 2 - (_frameSize / 2) - 120,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _frameColor.withOpacity(0.5), width: 1.5),
                  ),
                  child: Text(
                    _guidanceMessage,
                    style: TextStyle(
                      color: _frameColor, 
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            // Layer 4: Bottom Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildCameraControls(),
            ),

            // Layer 5: Back Button
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        )
      ),
    );
  }

  Widget _buildCameraControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.black.withOpacity(0.0),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery Preview Icon
          InkWell(
            onTap: _showCustomGallerySheet,
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library, color: Colors.white, size: 26),
            ),
          ),
          
          // Manual Shutter Button
          InkWell(
            onTap: _takePicture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: _isReadyToCapture
                    ? [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.8),
                          blurRadius: 20,
                          spreadRadius: 8,
                        )
                      ]
                    : [],
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: _isReadyToCapture ? Colors.greenAccent : Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 56), // Balance the layout
        ],
      ),
    );
  }

  Future<void> _runImageQualityCheck(PlatformFile result) async {
    try {
      final stableFile = await _copyToStablePath(result);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewCapturePage(
              originalImage: stableFile,
              editedImage: stableFile,
            ),
          ),
        ).then((_) {
          // Resume camera stream when returning from ReviewCapturePage
          _isTakingPicture = false;
          if (mounted && controller.value.isInitialized && ModalRoute.of(context)?.isCurrent == true) {
            _startDetectionStream();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to prepare image: $e")),
        );
      }
      _isTakingPicture = false;
      if (mounted && controller.value.isInitialized && ModalRoute.of(context)?.isCurrent == true) {
        _startDetectionStream();
      }
    }
  }

  Future<PlatformFile> _copyToStablePath(PlatformFile file) async {
    if (file.path == null) return file; 

    final srcFile = File(file.path!);
    final tmpDir = await getTemporaryDirectory();
    final ext = p.extension(file.path!).isEmpty ? '.jpg' : p.extension(file.path!);
    final destPath = p.join(
      tmpDir.path,
      'padiz_${DateTime.now().millisecondsSinceEpoch}$ext',
    );
    final copied = await srcFile.copy(destPath);
    return PlatformFile(
      name: file.name,
      path: copied.path,
      size: await copied.length(),
      bytes: file.bytes,
    );
  }

  Future<void> _showCustomGallerySheet() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    
    // If not authorized and not limited (some Android 13/14 devices return limited when users select specific photos)
    if (!ps.isAuth && ps != PermissionState.limited) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gallery permission denied. Using standard file picker.")),
        );
      }
      _launchStandardPicker();
      return;
    }

    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(ignoreSize: true),
        ),
      ),
    );

    if (paths.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No images found")));
      }
      return;
    }

    final AssetPathEntity recentPath = paths.first;
    final int assetCount = await recentPath.assetCountAsync;
    final List<AssetEntity> recentAssets = await recentPath.getAssetListRange(start: 0, end: math.min(100, assetCount));

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Select Photo",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(2),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: recentAssets.length,
                      itemBuilder: (context, index) {
                        final asset = recentAssets[index];
                        return InkWell(
                          onTap: () async {
                            Navigator.pop(context);
                            _processSelectedAsset(asset);
                          },
                          child: AssetThumbnail(asset: asset),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _processSelectedAsset(AssetEntity asset) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
    );

    final File? file = await asset.file;
    
    if (mounted) {
      Navigator.pop(context);
    }

    if (file == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load image file")));
      }
      return;
    }

    final double fileSizeInMB = file.lengthSync() / 1024 / 1024;
    if (fileSizeInMB > 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("The file is too large. Max Size is 8MB")));
      }
      return;
    }

    final String ext = p.extension(file.path).toLowerCase();
    if (['.jpg', '.png', '.webp', '.jpeg'].contains(ext)) {
      final result = PlatformFile(
        name: p.basename(file.path),
        path: file.path,
        size: file.lengthSync(),
      );
      await _runImageQualityCheck(result);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an image format")));
      }
    }
  }

  Future<void> _launchStandardPicker() async {
    PlatformFile? result = await pickPaddyImage();

    if (result == null || result.path == null) {
      return;
    }
    double fileSizeInMB = result.size / 1024 / 1024;
    if (fileSizeInMB > 8) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("The file is too large. Max Size is 8MB")));
      }
      return;
    }
    if (['jpg', 'png', 'webp', 'jpeg'].contains(result.extension?.toLowerCase())) {
      await _runImageQualityCheck(result);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an image format")),
        );
      }
    }
  }
}

class AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;

  const AssetThumbnail({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return Container(color: Colors.grey.shade200);
        return Image.memory(bytes, fit: BoxFit.cover);
      },
    );
  }
}

class OverlayPainter extends CustomPainter {
  final double frameSize;
  final Color frameColor;
  final double yOffset;

  OverlayPainter({
    required this.frameSize,
    required this.frameColor,
    this.yOffset = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the semi-transparent dark background
    final paintBg = Paint()
      ..color = Colors.black.withOpacity(0.65)
      ..style = PaintingStyle.fill;

    // The transparent frame rectangle
    final Rect frameRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 + yOffset),
      width: frameSize,
      height: frameSize,
    );

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paintBg);

    // Cut out the center frame
    final paintClear = Paint()
      ..blendMode = BlendMode.clear
      ..color = Colors.transparent;
    
    // Add rounded corners to the cutout
    final RRect rRect = RRect.fromRectAndRadius(frameRect, const Radius.circular(24));
    canvas.drawRRect(rRect, paintClear);
    canvas.restore();

    // 2. Draw the scanner frame corners
    final paintCorners = Paint()
      ..color = frameColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double cornerLen = 30.0;
    
    // Top Left
    canvas.drawPath(Path()
      ..moveTo(frameRect.left, frameRect.top + cornerLen)
      ..quadraticBezierTo(frameRect.left, frameRect.top, frameRect.left + cornerLen, frameRect.top), paintCorners);

    // Top Right
    canvas.drawPath(Path()
      ..moveTo(frameRect.right - cornerLen, frameRect.top)
      ..quadraticBezierTo(frameRect.right, frameRect.top, frameRect.right, frameRect.top + cornerLen), paintCorners);

    // Bottom Left
    canvas.drawPath(Path()
      ..moveTo(frameRect.left, frameRect.bottom - cornerLen)
      ..quadraticBezierTo(frameRect.left, frameRect.bottom, frameRect.left + cornerLen, frameRect.bottom), paintCorners);

    // Bottom Right
    canvas.drawPath(Path()
      ..moveTo(frameRect.right - cornerLen, frameRect.bottom)
      ..quadraticBezierTo(frameRect.right, frameRect.bottom, frameRect.right, frameRect.bottom - cornerLen), paintCorners);

    // 3. Draw the Leaf Silhouette Guide
    final paintSilhouette = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final leafPath = Path();
    final center = Offset(size.width / 2, size.height / 2 + yOffset);
    final w = frameSize * 0.4;
    final h = frameSize * 0.7;

    // Simple vector leaf shape centered in the frame
    leafPath.moveTo(center.dx, center.dy + h / 2);
    leafPath.quadraticBezierTo(center.dx - w, center.dy + h / 4, center.dx, center.dy - h / 2);
    leafPath.quadraticBezierTo(center.dx + w, center.dy + h / 4, center.dx, center.dy + h / 2);
    
    // Center vein
    leafPath.moveTo(center.dx, center.dy + h / 2);
    leafPath.lineTo(center.dx, center.dy - h / 2.5);

    canvas.drawPath(leafPath, paintSilhouette);
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.frameColor != frameColor || 
           oldDelegate.frameSize != frameSize ||
           oldDelegate.yOffset != yOffset;
  }
}
