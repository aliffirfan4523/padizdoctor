import 'package:flutter/material.dart';

Widget buildConfidenceScore(double score) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Confidence Match",
              style: TextStyle(fontWeight: FontWeight.w500)),
          Text("${(score * 100).toStringAsFixed(0)}%",
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: score,
        backgroundColor: Colors.grey[200],
        color: Colors.green,
        minHeight: 8,
      ),
    ],
  );
}
