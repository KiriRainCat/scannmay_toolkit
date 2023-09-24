import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';

import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/model/jupiter.dart';

class CourseView extends StatefulWidget {
  const CourseView({super.key});

  @override
  State<CourseView> createState() => _CourseViewState();
}

class _CourseViewState extends State<CourseView> {
  final lastUpdatedTime = AssignmentNotifierBgWorker.lastUpdateTime;
  final courses = AssignmentNotifierBgWorker.isar.jupiterDatas.filter().idEqualTo(0).findFirstSync()!.courses!;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Flex(
            direction: Axis.horizontal,
            children: [
              ElevatedButton(
                onPressed: () => Utils.openUrl("https://login.jupitered.com/login/"),
                child: const Text("前往 Jupiter Ed"),
              ),
              const SizedBox(width: 24),
              Obx(() => Text("上次数据更新于: $lastUpdatedTime")),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var course in courses) ...[
                    Container(
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
                          Text(course.name!),
                          const Expanded(child: SizedBox()),
                          Text(course.grade ?? "None"),
                        ],
                      ),
                    ),
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
