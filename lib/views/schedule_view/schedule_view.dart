import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:scannmay_toolkit/components/jupiter_data_status_bar.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/model/jupiter.dart';
import 'package:scannmay_toolkit/model/notification.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  final isar = AssignmentNotifierBgWorker.isar;
  late final StreamSubscription<JupiterNotification?> notificationStreamListener;

  final assignmentList = <Assignment>[];

  @override
  void initState() {
    fetchAssignmentsByDate();
    watchMessageQueue();
    super.initState();
  }

  @override
  void dispose() {
    notificationStreamListener.cancel();
    super.dispose();
  }

  // TODO: 备忘
  void fetchAssignmentsByDate() {
    assignmentList.clear();
    final courses = isar.jupiterDatas.getSync(0)!.courses;
    for (var course in courses!) {
      for (var assignment in course.assignments!) {
        if (assignment.due!.isNotEmpty) {
          final diffInDays = DateTime.parse(assignment.due!).difference(DateTime.now()).inDays;
          if (diffInDays > -1 && diffInDays < 5) {
            assignmentList.add(assignment);
          }
        }
      }
    }
  }

  void watchMessageQueue() {
    final notificationStream = isar.jupiterNotifications.watchObject(0);
    notificationStreamListener = notificationStream.listen((_) => fetchAssignmentsByDate());
  }

  String getDescStatus(String? raw) {
    if (raw == null) return "Instructions Not Fetched";
    if (raw == "None") return "No Instructions";
    return "Click to Check Instructions";
  }

  String formatDesc(String desc) {
    desc = desc.replaceFirst(RegExp(r'Directions\n'), "");
    desc = desc.split("\n").join("\n\n");
    return desc;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          const JupiterDataStatusBar(),
          const SizedBox(height: 16),
          const Text("作业日程表页面仍在开发中，敬请期待~ (开发者爆肝 ing)"),
          const SizedBox(height: 8),
          const Text("目前仅支持显示 5 日内需要完成的作业"),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 3,
              children: [
                for (var assignment in assignmentList) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: ElevatedButton(
                      onPressed: () {
                        if ((assignment.desc?.isNotEmpty ?? false) && assignment.desc != "None") {
                          Get.dialog(
                            AlertDialog(
                              title: const Text("Instructions"),
                              content: SizedBox(
                                width: 400,
                                child: Text(formatDesc(assignment.desc!)),
                              ),
                            ),
                          );
                        } else if (assignment.desc == null) {
                          // TODO: 检索数据，但是没法获取到 course，得另想办法
                        }
                      },
                      style: ButtonStyle(
                        splashFactory: NoSplash.splashFactory,
                        shape: MaterialStatePropertyAll(
                          ContinuousRectangleBorder(borderRadius: BorderRadiusDirectional.circular(4)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(Utils.formatDueDate(assignment.due!)),
                                Text(assignment.title!, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(getDescStatus(assignment.desc), style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                          const Checkbox(value: false, onChanged: null),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
