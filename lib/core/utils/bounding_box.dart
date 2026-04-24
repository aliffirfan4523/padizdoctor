import 'package:flutter/material.dart';

import '../../model/model.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<BoundingBoxes> detections;
  final Size imageSize;
  final String? activeLabel;

  BoundingBoxPainter(this.detections, this.imageSize, {this.activeLabel});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final detection in detections) {
      // Logic to determine color based on active tab
      final bool isActive = activeLabel != null &&
          detection.label.toLowerCase() == activeLabel!.toLowerCase();

      final Color mainColor =
          isActive ? Colors.black : const Color.fromARGB(255, 175, 76, 76);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isActive ? 3 : 2 // Thicker for active
        ..color = mainColor;

      // 1. Scaling Logic: model size → display size
      final scaleX = size.width / imageSize.width;
      final scaleY = size.height / imageSize.height;

      // 2. Use your manual BoundingBoxes properties
      final rect = Rect.fromLTRB(
        detection.x1 * scaleX,
        detection.y1 * scaleY,
        detection.x2 * scaleX,
        detection.y2 * scaleY,
      );

      // Draw rectangle
      canvas.drawRect(rect, paint);

      // 3. Draw Label (using individual detection confidence)
      textPainter.text = TextSpan(
        text: "${detection.label}",
        style: TextStyle(
          color: Colors.white,
          backgroundColor: mainColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );

      textPainter.layout();

      // Prevent label from drawing off-screen at the top
      double labelY = rect.top - 14;
      if (labelY < 0) labelY = rect.top + 2;

      textPainter.paint(
        canvas,
        Offset(rect.left, labelY),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
