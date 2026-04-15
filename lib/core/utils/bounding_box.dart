import 'package:flutter/material.dart';

import '../../model/model.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final double confidence_score;
  final Size imageSize;

  BoundingBoxPainter(this.detections, this.imageSize, this.confidence_score);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color.fromARGB(255, 175, 76, 76);

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final detection in detections) {
      // Scale bbox from model size → display size
      final scaleX = size.width / imageSize.width;
      final scaleY = size.height / imageSize.height;

      final rect = Rect.fromLTRB(
        detection.bbox.left * scaleX,
        detection.bbox.top * scaleY,
        detection.bbox.right * scaleX,
        detection.bbox.bottom * scaleY,
      );

      // Draw rectangle
      canvas.drawRect(rect, paint);

      // Draw label
      textPainter.text = TextSpan(
        text: "${(confidence_score * 100).toStringAsFixed(0)}%",
        style: const TextStyle(
          backgroundColor: Color.fromARGB(255, 175, 76, 76),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(rect.left, rect.top - 16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
