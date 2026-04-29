import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padizdoctor/app.dart';

import '../../../model/model.dart';
import '../../user/screens/detection_analysis_result.dart';

// ─────────────────────────────────────────────
// State enum
// ─────────────────────────────────────────────
enum ConfirmationState { success, analysisFailed, uploadFailed }

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────
class AnalysisConfirmationScreen extends StatelessWidget {
  final ConfirmationState state;
  final PlatformFile imageFile;

  /// Only provided on [ConfirmationState.success].
  final String? recordId;
  final String? imageId;

  /// Human-readable error for failure states.
  final String? errorMessage;

  /// Called by "Try Analysis Again" / "Retry Upload" → pops back to preview.
  final VoidCallback? onRetry;

  const AnalysisConfirmationScreen({
    super.key,
    required this.state,
    required this.imageFile,
    this.recordId,
    this.imageId,
    this.errorMessage,
    this.onRetry,
  });

  // ─── Navigation helpers ───────────────────────────────────────────────────

  /// Clears the entire nav stack back to the first route (home).
  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Navigates to the results screen and removes the full back-stack so the
  /// back button on the results screen returns to home, not this page.
  void _viewResults(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.analysisResult,
      (route) => route.isFirst, // keep only the very first route (home)
      arguments: AnalysisResultsArgs(
        recordId: recordId!,
        imageId: imageId!,
        userId: uid,
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildIcon(),
              const SizedBox(height: 28),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildSubtitle(),
              const SizedBox(height: 32),
              _buildImageCard(context),
              const Spacer(),
              _buildActions(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  AppBar _buildAppBar(BuildContext context) {
    final isSuccess = state == ConfirmationState.success;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: isSuccess
          ? null // no back on success — user should use the action buttons
          : IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
      title: Text(
        _appBarTitle,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 17),
      ),
      centerTitle: true,
      automaticallyImplyLeading: !isSuccess,
    );
  }

  String get _appBarTitle {
    switch (state) {
      case ConfirmationState.success:
        return 'Analysis Confirmation';
      case ConfirmationState.analysisFailed:
        return 'Analysis';
      case ConfirmationState.uploadFailed:
        return 'Upload Failed';
    }
  }

  // ─── Icon ─────────────────────────────────────────────────────────────────

  Widget _buildIcon() {
    switch (state) {
      case ConfirmationState.success:
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE8F5E9),
            border: Border.all(color: const Color(0xFF4CAF50), width: 2),
          ),
          child: const Icon(Icons.check_rounded,
              color: Color(0xFF4CAF50), size: 44),
        );

      case ConfirmationState.analysisFailed:
        return Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEF5350),
              ),
              child: const Icon(Icons.priority_high_rounded,
                  color: Colors.white, size: 44),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(Icons.image_not_supported_outlined,
                    color: Color(0xFF9E9E9E), size: 18),
              ),
            ),
          ],
        );

      case ConfirmationState.uploadFailed:
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFFFEBEE),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: Color(0xFFEF5350), size: 44),
            ),
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFFFA000), size: 20),
              ),
            ),
          ],
        );
    }
  }

  // ─── Title & subtitle ─────────────────────────────────────────────────────

  Widget _buildTitle() {
    final text = switch (state) {
      ConfirmationState.success => 'Analysis Ready!',
      ConfirmationState.analysisFailed => 'Analysis Failed',
      ConfirmationState.uploadFailed => 'Image Upload Failed',
    };
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    final text = switch (state) {
      ConfirmationState.success =>
        'Your image has been successfully uploaded and passed initial quality checks.',
      ConfirmationState.analysisFailed =>
        'We could not detect a disease pattern. This often happens if the image is blurry, too dark, or the leaf is not clearly visible.',
      ConfirmationState.uploadFailed =>
        "We couldn't upload or process your image for disease analysis.",
    };
    return Text(
      text,
      style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.grey.shade600),
      textAlign: TextAlign.center,
    );
  }

  // ─── Image card ───────────────────────────────────────────────────────────

  Widget _buildImageCard(BuildContext context) {
    final bool isSuccess = state == ConfirmationState.success;
    final bool isAnalysisFail = state == ConfirmationState.analysisFailed;

    Widget leading = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageFile.path != null
          ? Image.file(File(imageFile.path!), fit: BoxFit.cover)
          : const Icon(Icons.image, color: Colors.grey),
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      imageFile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _formattedTime(),
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.storage_rounded,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          _formattedSize(),
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    if (isAnalysisFail) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 13, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Detection error',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isSuccess)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF4CAF50), size: 22),
            ],
          ),
          if (isSuccess) ...[
            const SizedBox(height: 14),
            _buildProgressRow(context),
          ],
          if (state == ConfirmationState.uploadFailed) ...[
            const SizedBox(height: 14),
            _buildPossibleReasons(context),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pre-analysis Check',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
            Text('100%',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: const LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Color(0xFFE0E0E0),
            color: Color(0xFF4CAF50),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildPossibleReasons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 15, color: Color(0xFF1565C0)),
              const SizedBox(width: 6),
              Text(
                'POSSIBLE REASONS',
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1565C0),
                    letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _reasonRow(
            icon: Icons.wifi_off_rounded,
            title: 'Network Connection',
            subtitle:
                'Your internet connection may be unstable or disconnected.',
          ),
          const SizedBox(height: 8),
          _reasonRow(
            icon: Icons.blur_on_rounded,
            title: 'Image Quality',
            subtitle:
                'The image might be too blurry or dark for our AI to analyze.',
          ),
        ],
      ),
    );
  }

  Widget _reasonRow(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Action buttons ───────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    switch (state) {
      case ConfirmationState.success:
        return Column(
          children: [
            _primaryButton(
              context: context,
              label: 'View Detection Results →',
              onTap: () => _viewResults(context),
            ),
            const SizedBox(height: 12),
            _secondaryButton(
              context: context,
              icon: Icons.home_rounded,
              label: 'Return to Home',
              onTap: () => _goHome(context),
            ),
          ],
        );

      case ConfirmationState.analysisFailed:
        return Column(
          children: [
            _primaryButton(
              context: context,
              label: 'Try Analysis Again',
              icon: Icons.refresh_rounded,
              onTap: () {
                Navigator.pop(context); // back to ReviewCapturePage
                onRetry?.call();
              },
            ),
            const SizedBox(height: 12),
            _secondaryButton(
              context: context,
              icon: Icons.camera_alt_outlined,
              label: 'Upload New Image',
              onTap: () => _goHome(context),
            ),
          ],
        );

      case ConfirmationState.uploadFailed:
        return Column(
          children: [
            _primaryButton(
              context: context,
              label: 'Retry Upload',
              icon: Icons.refresh_rounded,
              color: const Color(0xFF4CAF50),
              onTap: () {
                Navigator.pop(context);
                onRetry?.call();
              },
            ),
            const SizedBox(height: 12),
            _secondaryButton(
              context: context,
              icon: Icons.image_outlined,
              label: 'Choose Another Image',
              onTap: () => _goHome(context),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _goHome(context),
              child: Text(
                'Cancel and return to home',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade500),
              ),
            ),
          ],
        );
    }
  }

  Widget _primaryButton({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
  }) {
    final bgColor = color ??
        (state == ConfirmationState.success
            ? const Color(0xFF1A1A1A)
            : const Color(0xFF1A1A1A));

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formattedTime() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _formattedSize() {
    final mb = imageFile.size / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}
