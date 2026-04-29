import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../model/MyActivityData.dart';

class ActivityHeader extends StatelessWidget {
  final ActivityData data;
  final Function(BuildContext, ActivityData) onCalendarTap;

  const ActivityHeader({
    super.key,
    required this.data,
    required this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthYear = DateFormat('MMM yyyy').format(now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trend Reports',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'User Overview • $monthYear',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: IconButton(
                icon: const Icon(Icons.calendar_today, size: 20),
                onPressed: () => onCalendarTap(context, data),
              ),
            ),
            const SizedBox(width: 8),
          ],
        )
      ],
    );
  }
}
