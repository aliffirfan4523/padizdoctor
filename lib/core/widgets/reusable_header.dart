import 'package:flutter/material.dart';

Widget buildHeader({
  required String title,
  bool enableViewAll = true,
  VoidCallback? onViewAll,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      if (enableViewAll)
        TextButton(
            onPressed: onViewAll ?? () {},
            child:
                const Text("View More", style: TextStyle(color: Colors.green))),
    ],
  );
}
