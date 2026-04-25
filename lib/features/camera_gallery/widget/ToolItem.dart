// ---------------- TOOL ITEM ----------------
import 'package:flutter/material.dart';

class ToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Function? onTap;

  const ToolItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Column(
        children: [
          Icon(icon, color: Colors.white, size: 22),
          SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      onPressed: () {
        if (onTap != null) {
          onTap!();
        }
      },
      tooltip: label,
    );
  }
}
