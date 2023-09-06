import 'package:flutter/material.dart';

class UnorderedListItem extends StatelessWidget {
  const UnorderedListItem({
    super.key,
    required this.text,
    this.textColor = Colors.black,
  });

  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.circle_sharp, color: Colors.black, size: 8),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}
