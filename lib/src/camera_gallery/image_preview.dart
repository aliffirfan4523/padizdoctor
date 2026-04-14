import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/src/camera_gallery/image_preview_service.dart';
import 'package:padizdoctor/src/camera_gallery/upload_loading.dart';

import 'gallery_service.dart';

class ReviewCapturePage extends StatefulWidget {
  final PlatformFile originalImage;
  PlatformFile editedImage;
  bool _isAnalyzing = false;
  final double? blurScore = 0;

  ReviewCapturePage({
    super.key,
    required this.originalImage,
    required this.editedImage,
  });

  @override
  State<ReviewCapturePage> createState() => _ReviewCapturePageState();
}

class _ReviewCapturePageState extends State<ReviewCapturePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isLoading = true; // Toggle this when API starts/ends

  Color acceptedColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true); // This makes it go back and forth

    _pulseAnimation = Tween<double>(begin: 1.0, end: 5.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFF0C1F14),
      appBar: _buildHeader(context),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 600, child: _buildImagePreview()),
            widget._isAnalyzing ? SizedBox() : _buildTools(),
            widget._isAnalyzing ? Container() : _buildRunButton(),
          ],
        ),
      ),
    );
  }

// Crop button
  Future<void> onCrop(BuildContext context) async {
    final result = await ImageEditService.cropImage(
      platformFile: widget.editedImage!,
      context: context,
    );

    if (result != null) {
      setState(() => widget.editedImage = result);
    }
  }

  void resetImageEdit() {
    setState(() {
      widget.editedImage = widget.originalImage;
    });
  }

  // ---------------- HEADER ----------------
  AppBar _buildHeader(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Review Image",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  // ---------------- IMAGE PREVIEW ----------------
  Widget _buildImagePreview() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        // Logic to switch colors based on loading vs result
        Color borderColor = widget._isAnalyzing ? Colors.blue : (acceptedColor);
        double glowSpread = widget._isAnalyzing ? _pulseAnimation.value : 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              //_statusBadge(),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: 3,
                    ),
                    boxShadow: [
                      if (_isLoading) // Only show glow when analyzing
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: glowSpread * 2,
                          spreadRadius: glowSpread,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: InteractiveViewer(
                      minScale: 0.2,
                      maxScale: 4,
                      child: Image.file(
                        File(widget.editedImage.path!),
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _focusVerified(), // You might want to hide this if _isLoading is true
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E3A22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: acceptedColor),
      ),
      child: Text(
        widget._isAnalyzing ? "✓ AI READY" : "✗ AI NOT READY",
        style: TextStyle(
          color: acceptedColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _focusVerified() {
    return Column(
      children: [
        //Icon(widget.status ? Icons.check_circle : Icons.block, color: widget.status ? acceptedColor : rejectedColor, size: 28),
        SizedBox(height: 6),
        Text(
          widget._isAnalyzing ? "Analysis Pending." : "Image Staged",
          style: TextStyle(
            color: acceptedColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          widget._isAnalyzing
              ? "Inference is pending. Please wait while we analyze the image quality and provide feedback."
              : "Image is staged and ready... Tap 'Run Diagnosis' to start the AI analysis.",
          style: TextStyle(
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ---------------- TOOLS ----------------
  Widget _buildTools() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF102A1B),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolItem(
              icon: Icons.edit,
              label: "Edit",
              onTap: () => onCrop(context),
            ),
            _ToolItem(
              icon: Icons.refresh,
              label: "Reset",
              onTap: () => resetImageEdit(),
            ),
            _ToolItem(
              icon: Icons.image_rounded,
              label: "Change \nImage",
              onTap: () => {Navigator.pop(context)},
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- RUN BUTTON ----------------
  Widget _buildRunButton() {
    return InkWell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                // 1. Show loading screen
                widget._isAnalyzing = true;
                setState(() {});

                final result = await inferenceImage(widget.editedImage);
                widget._isAnalyzing = false;
                setState(() {});
                print("Diagnosis success: ${result['label']}");
                // TODO: Navigate to results page
              } catch (e) {
                widget._isAnalyzing = false;
                setState(() {});

                // This catches the 'throw Exception' from 422, 429, or 500
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceAll("Exception: ", "")),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            icon: widget._isAnalyzing ? Icon(Icons.block) : Icon(Icons.biotech),
            label: Text(
              widget._isAnalyzing ? "" : "Run Diagnosis",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: acceptedColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- TOOL ITEM ----------------
class _ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Function? onTap;

  const _ToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      onPressed: () {
        if (onTap != null) {
          onTap!();
        }
      },
      tooltip: label,
    );
  }
}
