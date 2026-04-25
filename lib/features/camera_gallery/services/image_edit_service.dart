import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageEditService {
  // ---------------- CROP ONLY ----------------
  static Future<PlatformFile?> cropImage({
    required PlatformFile platformFile,
    required BuildContext context,
  }) async {
    if (platformFile.path == null) return null;

    // The file_picker cache path can be evicted by Android before ImageCropper
    // opens it. Copy the file to the app's own temp directory first — a stable
    // location the OS won't touch while the app is running.
    final String stablePath = await _ensureStablePath(platformFile);

    final cropped = await ImageCropper().cropImage(
      sourcePath: stablePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit Image',
          toolbarColor: const Color(0xFF0C1F14),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF00FF66),
          lockAspectRatio: false,
          showCropGrid: true,
        ),
        IOSUiSettings(
          title: 'Edit Image',
          aspectRatioLockEnabled: false,
          rotateButtonsHidden: true,
          resetButtonHidden: true,
        ),
      ],
    );

    if (cropped == null) return null;

    return PlatformFile(
      name: platformFile.name,
      path: cropped.path,
      size: await File(cropped.path).length(),
    );
  }

  /// Copies [platformFile] to the app's temp directory if its current path
  /// is not already inside a stable location. Returns the stable path.
  static Future<String> _ensureStablePath(PlatformFile platformFile) async {
    final srcPath = platformFile.path!;
    final srcFile = File(srcPath);

    if (!await srcFile.exists()) {
      throw Exception(
        'Source image file not found at: $srcPath\n'
        'The file may have been removed from the picker cache. '
        'Please select the image again.',
      );
    }

    // If already in app temp/documents, no need to copy.
    final tmpDir = await getTemporaryDirectory();
    if (srcPath.startsWith(tmpDir.path)) return srcPath;

    // Copy to app temp dir so ImageCropper always gets a live file.
    final destPath = p.join(
      tmpDir.path,
      'padiz_crop_${DateTime.now().millisecondsSinceEpoch}${p.extension(srcPath).isEmpty ? '.jpg' : p.extension(srcPath)}',
    );
    await srcFile.copy(destPath);
    return destPath;
  }
}
