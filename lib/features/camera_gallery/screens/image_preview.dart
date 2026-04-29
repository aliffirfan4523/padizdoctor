import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:padizdoctor/core/services/location_service.dart';
import 'package:padizdoctor/features/camera_gallery/screens/analysis_confirmation.dart';
import 'package:padizdoctor/features/camera_gallery/services/image_edit_service.dart';
import 'package:padizdoctor/features/camera_gallery/screens/upload_loading.dart';
import 'package:padizdoctor/features/camera_gallery/widget/ToolItem.dart';

import '../../../model/llm_result.dart';
import '../../../model/model.dart';
import '../services/gallery_service.dart';

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
            SizedBox(height: 500, child: _buildImagePreview()),
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

  // ---------------- HELPERS ----------------

  /// Parses bbox from either List [x1,y1,x2,y2] or Map {"x1","y1","x2","y2"}.
  static double _bbox(dynamic bbox, int listIdx, String mapKey) {
    if (bbox is List) return (bbox[listIdx] as num).toDouble();
    if (bbox is Map) return (bbox[mapKey] as num).toDouble();
    throw Exception('Unexpected bbox format: ${bbox.runtimeType}');
  }

  /// Parses expert_advice, which always has the shape:
  /// {
  ///   "status": "success",
  ///   "results": {
  ///     // Healthy:
  ///     "Healthy": { "health_status": "Healthy", "advice": "..." }
  ///     // OR diseased:
  ///     "rice_blast": { "severity": "...", "treatment": "...", "symptoms": [...], "source": "..." }
  ///   }
  /// }
  static List<ExpertAdvice> _parseExpertAdvice(Map<String, dynamic> raw) {
    // The actual data lives inside "results". Fall back to the top-level map
    // for older API responses that don't have the wrapper.
    final Map<String, dynamic> results =
        (raw['results'] as Map?)?.cast<String, dynamic>() ?? raw;

    // Iterate over every entry in results.
    final List<ExpertAdvice> advice = [];
    for (final entry in results.entries) {
      final val = entry.value;

      // Skip metadata keys that are just strings/primitives (e.g., "status": "success")
      if (val is! Map) continue;

      if (entry.key == 'Healthy') {
        // Healthy entry inside "results"
        final detail = val.cast<String, dynamic>();
        advice.add(ExpertAdvice(
          diseaseName: 'Healthy',
          status: detail['health_status'] ?? 'Healthy',
          severity: 'None',
          treatment:
              detail['advice'] ?? raw['advice'] ?? 'No treatment needed.',
          symptoms: 'None',
          source: 'AI Inference',
        ));
      } else {
        // Disease entry.
        final detail = val.cast<String, dynamic>();
        advice.add(ExpertAdvice(
          diseaseName: entry.key,
          status: entry.key,
          severity: detail['severity'] ?? 'unknown',
          treatment: detail['treatment'] ?? 'Consult a specialist.',
          symptoms: (detail['symptoms'] as List? ?? []).join(', '),
          source: detail['source'] ?? 'AI Inference',
        ));
      }
    }

    // Should never be empty, but guard anyway.
    if (advice.isEmpty) {
      advice.add(ExpertAdvice(
        diseaseName: 'Healthy',
        status: 'Healthy',
        severity: 'None',
        treatment: 'No treatment needed.',
        symptoms: 'None',
        source: 'AI Inference',
      ));
    }

    return advice;
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
                          color: Colors.black.withValues(alpha: 0.2),
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
            ToolItem(
              icon: Icons.edit,
              label: "Edit",
              onTap: () => onCrop(context),
            ),
            ToolItem(
              icon: Icons.refresh,
              label: "Reset",
              onTap: () => resetImageEdit(),
            ),
            ToolItem(
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
              // ── Phase 1: API inference ──────────────────────────────────
              // Inner try/catch handles ML/API errors (blurry image, server
              // errors, bad format). On failure → AnalysisFailed screen.
              LlmResult? llmResult;
              Position? scanPosition;
              String? locationName;
              try {
                setState(() => widget._isAnalyzing = true);

                // Capture GPS location in parallel with inference
                final locationFuture = LocationService.getCurrentPosition();
                final result = await inferenceImage(widget.editedImage);
                scanPosition = await locationFuture;

                // Reverse geocode in background (don't block the flow)
                if (scanPosition != null) {
                  locationName = await LocationService.reverseGeocode(
                    scanPosition.latitude,
                    scanPosition.longitude,
                  );
                }

                llmResult = LlmResult(
                  detections: [
                    for (var det in result['detections'])
                      BoundingBoxes(
                        confidence:
                            (det['confidence'] as num?)?.toDouble() ?? 0.0,
                        label: det['class'] ?? 'unknown',
                        x1: _bbox(det['bbox'], 0, 'x1'),
                        y1: _bbox(det['bbox'], 1, 'y1'),
                        x2: _bbox(det['bbox'], 2, 'x2'),
                        y2: _bbox(det['bbox'], 3, 'y2'),
                        width: _bbox(det['bbox'], 2, 'x2') -
                            _bbox(det['bbox'], 0, 'x1'),
                        height: _bbox(det['bbox'], 3, 'y2') -
                            _bbox(det['bbox'], 1, 'y1'),
                      )
                  ],
                  count: (result['count'] as num).toInt(),
                  processing_time_ms:
                      (result['processing_time_ms'] as num).toDouble(),
                  expert_advice: _parseExpertAdvice(result['expert_advice']),
                  original_height: (result['original_height'] as num).toInt(),
                  original_width: (result['original_width'] as num).toInt(),
                );
              } on Exception catch (inferenceError) {
                setState(() => widget._isAnalyzing = false);
                if (!context.mounted) return;
                print("inferenceError: $inferenceError");
                final errorStr = inferenceError.toString();
                final isNetworkError = errorStr.contains('SocketException') ||
                    errorStr.contains('ClientException') ||
                    errorStr.contains('Failed host lookup') ||
                    errorStr.contains('Connection refused') ||
                    errorStr.contains('NETWORK_ERROR') ||
                    errorStr.contains('status: 500') ||
                    errorStr.contains('status: 503') ||
                    errorStr.contains('status: 504');

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnalysisConfirmationScreen(
                      state: isNetworkError
                          ? ConfirmationState.uploadFailed
                          : ConfirmationState.analysisFailed,
                      imageFile: widget.editedImage,
                      errorMessage: errorStr.replaceAll('Exception: ', ''),
                    ),
                  ),
                );
                return;
              }

              String recordId;
              try {
                // ── Phase 2: Firebase save ────────────────────────────────
                recordId = await addInferenceResultToHistory(
                    llmResult, widget.editedImage,
                    position: scanPosition, locationName: locationName);
              } on Exception catch (uploadError) {
                // Network / Upload failure → Upload Failed screen
                setState(() => widget._isAnalyzing = false);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnalysisConfirmationScreen(
                      state: ConfirmationState.uploadFailed,
                      imageFile: widget.editedImage,
                      errorMessage:
                          uploadError.toString().replaceAll('Exception: ', ''),
                    ),
                  ),
                );
                return;
              }

              // ── Success: navigate to confirmation screen ──────────────
              setState(() => widget._isAnalyzing = false);
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AnalysisConfirmationScreen(
                    state: ConfirmationState.success,
                    imageFile: widget.editedImage,
                    recordId: recordId,
                    imageId: recordId, // nowId is used for both record & image
                  ),
                ),
              );
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
