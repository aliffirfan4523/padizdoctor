import 'package:flutter/material.dart';
import 'package:padizdoctor/features/camera_gallery/screens/analysis_confirmation.dart';

class AnalysisConfirmationArgs {
  final ConfirmationState state;

  /// PlatformFile — typed as dynamic to avoid a circular import from app.dart.
  final dynamic imageFile;
  final String? recordId;
  final String? imageId;
  final String? errorMessage;
  final VoidCallback? onRetry;
  const AnalysisConfirmationArgs({
    required this.state,
    required this.imageFile,
    this.recordId,
    this.imageId,
    this.errorMessage,
    this.onRetry,
  });
}
