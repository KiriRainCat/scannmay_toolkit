import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/model/jupiter.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
  });

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Flex(
        direction: Axis.horizontal,
        children: [
          Text(course.name!, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Expanded(child: SizedBox()),
          Text(course.grade ?? "None"),
        ],
      ),
    );
  }
}
