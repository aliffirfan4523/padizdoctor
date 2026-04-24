import 'package:flutter/material.dart';

Widget buildTreatmentList(List<dynamic> treatments) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      children: treatments
          .map((tx) => ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(tx['treatment_text']),
              ))
          .toList(),
    ),
  );
}
