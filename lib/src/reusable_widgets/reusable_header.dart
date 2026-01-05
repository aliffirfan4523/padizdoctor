import 'package:flutter/material.dart';

Widget buildHeader({required String title, bool enableViewAll = true}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      if (enableViewAll)
        TextButton(
            onPressed: () {},
            child: const Text("View More",
                style: const TextStyle(color: Colors.greenAccent))),
    ],
  );
}
