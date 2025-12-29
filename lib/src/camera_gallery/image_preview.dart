import 'package:flutter/material.dart';
import 'package:padizdoctor/src/reusable_widgets/text_button.dart';

class ImagePreview extends StatefulWidget {
  const ImagePreview({super.key});

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Review Capture"),
          actions: [TextButton(onPressed: () {}, child: Text("Retake"))],
        ),
        bottomNavigationBar: TextColorButton(Colors.green, "Use Photo", () {}),
        body: Center());
  }
}
