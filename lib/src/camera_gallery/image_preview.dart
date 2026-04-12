import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/src/camera_gallery/image_preview_service.dart';

import 'gallery_service.dart';

class ReviewCapturePage extends StatefulWidget {
  final PlatformFile originalImage;
  PlatformFile editedImage;
  bool status;
  final double? blurScore;

  ReviewCapturePage(
      {super.key,
      required this.originalImage,
      required this.editedImage,
      required this.status,
      this.blurScore});

  @override
  State<ReviewCapturePage> createState() => _ReviewCapturePageState();
}

class _ReviewCapturePageState extends State<ReviewCapturePage> {
  Color acceptedColor = Colors.green;
  Color rejectedColor = Colors.red;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFF0C1F14),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildImagePreview()),
            widget.status
                ? _buildTools()
                : Container(
                    height: 100,
                    child: Center(
                      child: Text(
                        "Blur Score: ${widget.blurScore}",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
            _buildRunButton(),
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
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "Review Capture",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Retake logic
              Navigator.pop(context);
            },
            child: const Text(
              "Retake",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      ),
    );
  }

  // ---------------- IMAGE PREVIEW ----------------
  Widget _buildImagePreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _statusBadge(),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.status ? acceptedColor : rejectedColor,
                  width: 3,
                ),
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
          _focusVerified(),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0E3A22),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: widget.status ? acceptedColor : rejectedColor),
      ),
      child: Text(
        widget.status ? "✓ AI READY" : "✗ AI NOT READY",
        style: TextStyle(
          color: widget.status ? acceptedColor : rejectedColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _focusVerified() {
    return Column(
      children: [
        Icon(widget.status ? Icons.check_circle : Icons.block,
            color: widget.status ? acceptedColor : rejectedColor, size: 28),
        SizedBox(height: 6),
        Text(
          widget.status ? "Focus Verified" : "Focus Not Verified",
          style: TextStyle(
            color: widget.status ? acceptedColor : rejectedColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          widget.status
              ? "Image is clear and ready for disease analysis"
              : "Image is blurry. Please retake the photo.",
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
              // TODO: Run diagnosis
              await inferenceImage(widget.editedImage);
            },
            icon: widget.status ? Icon(Icons.biotech) : Icon(Icons.block),
            label: Text(
              widget.status ? "Run Diagnosis" : "",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.status ? acceptedColor : rejectedColor,
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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
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
