import 'package:isar/isar.dart';
import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/model/jupiter.dart';
import 'package:scannmay_toolkit/views/course_view/course_card.dart';
import 'package:scannmay_toolkit/components/jupiter_data_status_bar.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';

class CourseView extends StatefulWidget {
  const CourseView({super.key});

  @override
  State<CourseView> createState() => _CourseViewState();
}

class _CourseViewState extends State<CourseView> {
  final courses = AssignmentNotifierBgWorker.isar.jupiterDatas.filter().idEqualTo(0).findFirstSync()!.courses!;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          const JupiterDataStatusBar(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var course in courses) ...[
                    CourseCard(course: course),
                    const SizedBox(height: 12),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
