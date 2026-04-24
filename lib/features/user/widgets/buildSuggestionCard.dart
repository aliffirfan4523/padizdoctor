import 'package:flutter/material.dart';

Widget buildSuggestionCard(Map<String, dynamic> sug) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, color: Colors.green, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sug['type'] ?? 'AI Suggestion', // e.g., 'LLM' or 'RuleBased'
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                sug['text'] ?? '',
                style: TextStyle(color: Colors.grey[800], height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
