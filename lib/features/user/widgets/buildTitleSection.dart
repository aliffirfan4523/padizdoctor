import 'package:flutter/material.dart';

Widget buildTitleSection(String name, String severity) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          severity.toUpperCase(),
          style: const TextStyle(
              color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    ],
  );
}
