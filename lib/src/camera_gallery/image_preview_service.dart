import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageEditService {
  // ---------------- CROP ONLY ----------------
  static Future<PlatformFile?> cropImage({
    required PlatformFile platformFile,
    required BuildContext context,
  }) async {
    if (platformFile.path == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: platformFile.path!,
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
}
