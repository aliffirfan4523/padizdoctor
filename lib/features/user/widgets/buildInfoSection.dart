import 'package:flutter/material.dart';

Widget buildInfoSection(String title, String content) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text(content, style: TextStyle(height: 1.5)),
    ],
  );
}
