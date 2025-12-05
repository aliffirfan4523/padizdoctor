import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GalleryPicker extends StatefulWidget {
  const GalleryPicker({super.key});

  @override
  State<GalleryPicker> createState() => _GalleryPickerState();
}

class _GalleryPickerState extends State<GalleryPicker> {
  XFile? _image;

  @override
  void initState() {
    super.initState();
    _openGallery();
  }

  Future<void> _openGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _image = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select from Gallery")),
      body: Center(
        child: _image == null
            ? const Text(
                "No image selected.\nGallery was opened automatically.",
                textAlign: TextAlign.center,
              )
            : Image.file(
                File(_image!.path),
                width: 250,
              ),
      ),
    );
  }
}
