import 'dart:io';

import 'package:blur_detection/blur_detection.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

class GalleryPicker extends StatefulWidget {
  const GalleryPicker({super.key});

  @override
  State<GalleryPicker> createState() => _GalleryPickerState();
}

class _GalleryPickerState extends State<GalleryPicker> {
  final ImagePicker _picker = ImagePicker(); // Initialize the picker
  File? _image;
  String _result = '';
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  // camera_view.dart
  final cameras = GetIt.instance<List<CameraDescription>>();

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    _initializeControllerFuture = controller.initialize();
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File file = File(image.path);

      // This package returns true if blurred, false if clear
      final bool isBlurred = await BlurDetectionService.isImageBlurred(file);

      setState(() {
        _image = file;
        _result = isBlurred
            ? "The image is blurry. Please retake."
            : "The image is clear.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: const Text('Blur Detector Example'),
          ),
          body: Stack(
            children: [
              // Layer 1: The Camera Feed
              // Layer 1: The Camera Feed
              Positioned.fill(
                // This forces the container to fill the entire stack space
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit
                          .cover, // Automatically handles the scaling without complex math
                      child: SizedBox(
                        width: controller.value.previewSize!.height,
                        height: controller.value.previewSize!.width,
                        child: CameraPreview(controller),
                      ),
                    ),
                  ),
                ),
              ),

              // Layer 2: The Scanning Frame (The Green Corners)
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.transparent), // Space for corners
                  ),
                  child: CustomPaint(painter: ScannerFramePainter()),
                ),
              ),

              // Layer 3: Top Overlay (Instruction Text)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Align leaf within the frame",
                      style: TextStyle(color: Colors.white, fontSize: 14),
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
            ],
          )),
    );
  }

  Widget _buildCameraControls() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      decoration: BoxDecoration(
        color: Color(0xFF0B140E), // Very dark green/black
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("STATUS: ACTIVE",
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 8),
          Text("Hold steady for accurate analysis",
              style: TextStyle(color: Colors.white70)),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Gallery Preview Icon
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.image, color: Colors.white),
              ),
              // The Big Green Shutter Button
              _buildShutterButton(),
              // Flip Camera Icon
              IconButton(
                icon:
                    Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShutterButton() {
    return InkWell(
      onTap: () async {
        try {
          await _initializeControllerFuture;
          final image = await controller.takePicture();
          if (!mounted) return;
          setState(() {
            _image = File(image.path);
          });
        } catch (e) {
          print(e);
        }
      },
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: Color(0xFF00FF41), // Neon Green
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class ScannerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF00FF41)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    double len = 25; // Length of the corner lines

    // Top Left
    canvas.drawLine(Offset(0, 0), Offset(len, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, len), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // ... Repeat for Bottom Left and Bottom Right
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
