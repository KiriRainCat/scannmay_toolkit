import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/model/notification.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.message,
  });

  final Message message;

  String formatDueDate(String raw) {
    if (raw.isEmpty) return "00/00";
    final parts = raw.split("/");
    if (parts[0].length < 2) parts[0] = "0${parts[0]}";
    if (parts[1].length < 2) parts[1] = "0${parts[1]}";
    return parts.join("/");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            spreadRadius: 0.25,
            blurRadius: 6,
            color: Colors.black.withAlpha(15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("${message.title}"),
              const SizedBox(width: 12),
              Text(Utils.formatTime(message.time!)),
              const SizedBox(width: 12),
              Text("${message.course}"),
            ],
          ),
          for (var assignment in message.assignments!) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(formatDueDate(assignment.due!)),
                const SizedBox(width: 12),
                Text(
                  assignment.title!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Text("[ ${assignment.score!} ]"),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
