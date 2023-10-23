import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/model/jupiter.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/components/jupiter_data_status_bar.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  final isar = AssignmentNotifierBgWorker.isar;
  late final StreamSubscription<JupiterData?> notificationStreamListener;

  List<Assignment> assignmentList = [];

  List<int?> selectedFilter = [7, null];

  @override
  void initState() {
    fetchAssignmentsWithFilter();
    watchChanges();
    super.initState();
  }

  @override
  void dispose() {
    notificationStreamListener.cancel();
    super.dispose();
  }

  void fetchAssignmentsWithFilter() {
    final list = <Assignment>[];
    final courses = isar.jupiterDatas.getSync(0)!.courses;
    for (var course in courses!) {
      for (var assignment in course.assignments!) {
        if (assignment.due!.isNotEmpty) {
          final diffInDays = DateTime.parse(assignment.due!).difference(DateTime.now()).inDays;
          if (diffInDays > -1 && diffInDays < selectedFilter[0]! && assignment.status == selectedFilter[1]) {
            list.add(assignment..from = course.name);
          }
        }
      }
    }
    setState(() => assignmentList = list);
  }

  void watchChanges() {
    final notificationStream = isar.jupiterDatas.watchObject(0);
    notificationStreamListener = notificationStream.listen((_) => fetchAssignmentsWithFilter());
  }

  void updateAssignmentStatus(bool status, String course, Assignment assignment) async {
    final jupiterData = await isar.jupiterDatas.get(0);
    final target = jupiterData!.courses!
        .firstWhere((c) => c.name == course)
        .assignments!
        .firstWhere((a) => a.due == assignment.due && a.title == assignment.title);
    target.status = status ? 1 : null;
    isar.writeTxn(() => isar.jupiterDatas.put(jupiterData));
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
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Flex(
              direction: Axis.horizontal,
              children: [
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedFilter[0],
                    items: [
                      DropdownMenuItem(value: 3, child: Text("${"deadlineTill".tr} 3 ${"daysTillHomework".tr}")),
                      DropdownMenuItem(value: 5, child: Text("${"deadlineTill".tr} 5 ${"daysTillHomework".tr}")),
                      DropdownMenuItem(value: 7, child: Text("${"deadlineTill".tr} 7 ${"daysTillHomework".tr}")),
                      DropdownMenuItem(value: 14, child: Text("${"deadlineTill".tr} 14 ${"daysTillHomework".tr}")),
                      DropdownMenuItem(value: 30, child: Text("${"deadlineTill".tr} 30 ${"daysTillHomework".tr}")),
                    ],
                    onChanged: (value) {
                      setState(() => selectedFilter[0] = value);
                      fetchAssignmentsWithFilter();
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField(
                    value: selectedFilter[1],
                    items: [
                      DropdownMenuItem(value: null, child: Text("incomplete".tr)),
                      DropdownMenuItem(value: 1, child: Text("complete".tr)),
                    ],
                    onChanged: (value) {
                      setState(() => selectedFilter[1] = value);
                      fetchAssignmentsWithFilter();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 2.8,
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
                                Text(
                                  "[ From: ${assignment.from!} ]",
                                  style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                          Checkbox(
                            value: (assignment.status == null) ? false : true,
                            onChanged: (value) {
                              updateAssignmentStatus(value!, assignment.from!, assignment);
                              assignmentList.removeWhere((a) => a.due == assignment.due && a.title == assignment.title);
                              setState(() => assignmentList = assignmentList);
                            },
                          ),
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
