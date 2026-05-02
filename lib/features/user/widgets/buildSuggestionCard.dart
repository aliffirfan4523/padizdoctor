import 'package:flutter/material.dart';

Widget buildSuggestionCard(Map<String, dynamic> sug) {
  final String fullText = sug['text'] ?? '';
  final String type = sug['type'] ?? 'AI Suggestion';

  // Parsing logic for Organic and Chemical sections
  String? organicText;
  String? chemicalText;
  String? otherText;

  final organicMatch = RegExp(r"Organic:\s*(.*?)(?=Chemical:|$)",
          caseSensitive: false, dotAll: true)
      .firstMatch(fullText);
  final chemicalMatch = RegExp(r"Chemical:\s*(.*)",
          caseSensitive: false, dotAll: true)
      .firstMatch(fullText);

  if (organicMatch != null || chemicalMatch != null) {
    organicText = organicMatch?.group(1)?.trim();
    chemicalText = chemicalMatch?.group(1)?.trim();
  } else {
    otherText = fullText.trim();
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtle header indicating source/type
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.05),
              border: Border(
                  bottom:
                      BorderSide(color: Colors.green.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.green, size: 14),
                const SizedBox(width: 8),
                Text(
                  type.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.green,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (organicText != null && organicText.isNotEmpty)
                  _buildMethodSection(
                    "Organic Method",
                    organicText,
                    Icons.nature_outlined,
                    Colors.green,
                  ),
                if (organicText != null &&
                    organicText.isNotEmpty &&
                    chemicalText != null &&
                    chemicalText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                        height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                if (chemicalText != null && chemicalText.isNotEmpty)
                  _buildMethodSection(
                    "Chemical Method",
                    chemicalText,
                    Icons.science_outlined,
                    Colors.blue,
                  ),
                if (otherText != null && otherText.isNotEmpty)
                  Text(
                    otherText,
                    style: TextStyle(
                      color: Colors.grey[800],
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildMethodSection(
    String title, String content, IconData icon, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        content,
        style: TextStyle(
          color: Colors.grey[800],
          height: 1.6,
          fontSize: 14,
        ),
      ),
    ],
  );
}
