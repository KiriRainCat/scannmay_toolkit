import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/constants.dart';
import 'package:scannmay_toolkit/model/jupiter.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/functions/utils/logger.dart';
import 'package:scannmay_toolkit/components/rounded_button.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
  });

  final Course course;

  void showCourseInfo(BuildContext context) {
    final courses = AssignmentNotifierBgWorker.isar.jupiterDatas.filter().idEqualTo(0).findFirstSync()!.courses!;
    final assignments = courses.firstWhere((item) => item.name == course.name).assignments!
      ..sort(
        (a, b) {
          if (a.due == null || a.due!.isEmpty) return 1;
          if (b.due == null || b.due!.isEmpty) return 1;
          return DateTime.parse(b.due!).compareTo(DateTime.parse(a.due!));
        },
      );

    Get.dialog(
      Dialog.fullscreen(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back, size: 24, color: Colors.black),
                  ),
                ],
              ),
              Text(
                course.name!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              Text(
                course.grade ?? "None",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      for (var assignment in assignments) ...[
                        ElevatedButton(
                          style: ButtonStyle(
                            splashFactory: NoSplash.splashFactory,
                            shape: MaterialStatePropertyAll(
                              ContinuousRectangleBorder(borderRadius: BorderRadiusDirectional.circular(0)),
                            ),
                          ),
                          onPressed: () => showAssignmentInfo(assignment),
                          child: Flex(
                            direction: Axis.horizontal,
                            children: [
                              Text(
                                Utils.formatDueDate(assignment.due!),
                                style: const TextStyle(color: Colors.black),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                assignment.title!,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              const Expanded(child: SizedBox()),
                              Text(
                                assignment.score! == "Complete" ? "☑" : assignment.score!,
                                style: const TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: Colors.black.withAlpha(1), height: 1)
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TODO: 在 Notification Card 中也有类似方法，记得以后提取出来
  void fetchAssignmentDesc(String assignmentTitle) async {
    Get.back();
    Get.back();
    UI.showNotification("info1".tr);

    // 打开浏览器并登录 Jupiter
    final jupiterPage = await AssignmentNotifierBgWorker.openJupiterPage();
    if (jupiterPage == null) return;
    if (!(await AssignmentNotifierBgWorker.login(jupiterPage))) return;

    // 前往对应课程页
    final courses = await AssignmentNotifierBgWorker.getCourses(jupiterPage);
    late final int idx;
    for (var i = 0; i < courses.length; i++) {
      if (await courses[i].evaluate("node => node.innerText") == course.name) {
        idx = i;
        break;
      }
    }

    try {
      courses[idx].hover();
      await Future.delayed(Constants.universalDelay);
      jupiterPage.mouse.down();
      jupiterPage.mouse.up();
      await jupiterPage.waitForSelector("div[class='hide null']");
      await Future.delayed(Constants.universalDelay);
    } catch (e) {
      Log.logger.e("browserClose".tr, error: e);
      AssignmentNotifierBgWorker.dataFetchStatus.value = "-$e";
      UI.showNotification("${"err3".tr}: $e", type: NotificationType.error);
      await AssignmentNotifierBgWorker.closeBrowser();
      return;
    }

    // 获取数据库数据
    final jupiterData = (await AssignmentNotifierBgWorker.isar.jupiterDatas.filter().idEqualTo(0).findFirst())!;
    final c = jupiterData.courses!.firstWhere((item) => item.name == course.name);
    final assignments = [Assignment()..title = assignmentTitle];

    // 查询作业详情并写入数据库
    await AssignmentNotifierBgWorker.getAssignmentDesc(jupiterPage, c, assignments);
    AssignmentNotifierBgWorker.isar.writeTxn(() => AssignmentNotifierBgWorker.isar.jupiterDatas.put(jupiterData));

    await AssignmentNotifierBgWorker.closeBrowser();
    AssignmentNotifierBgWorker.dataFetchStatus.value = "+";
    Log.logger.i("browserClose".tr);
    UI.showNotification("$assignmentTitle ${"info2".tr}");
  }

  void showAssignmentInfo(Assignment assignment) async {
    var desc = assignment.desc;

    desc ??= "Not Fetched";
    desc = desc.replaceFirst(RegExp(r'Directions\n'), "");
    desc = desc.split("\n").join("\n\n");

    Get.dialog(
      Dialog(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                RoundedButton(
                  onPressed: () => fetchAssignmentDesc(assignment.title!),
                  tooltip: "${desc == 'Not Fetched' ? '' : '重新'}检索 Directions 信息",
                  buttonContent: Icon(Icons.replay_outlined, size: 18, color: Colors.blue.shade900),
                  margin: const EdgeInsets.fromLTRB(0, 8, 10, 0),
                  width: 20,
                  height: 20,
                ),
                RoundedButton(
                  onPressed: () => Get.back(),
                  buttonContent: Icon(Icons.close, size: 18, color: Colors.red.shade900),
                  margin: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                  width: 20,
                  height: 20,
                ),
              ],
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(), // 占位符，用于撑满整个 Column 的水平轴
                      Text(assignment.title!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text("From: ${course.name}"),
                      const SizedBox(height: 4),
                      Text("Due: ${Utils.formatDueDate(assignment.due!)}"),
                      const SizedBox(height: 4),
                      Text("Score: [ ${assignment.score} ]"),
                      const SizedBox(height: 16),
                      const Text("Directions: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SelectionArea(child: Text(desc)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(2),
      child: ElevatedButton(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadiusDirectional.circular(4))),
        ),
        onPressed: () => showCourseInfo(context),
        child: Flex(
          direction: Axis.horizontal,
          children: [
            Text(course.name!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            const Expanded(child: SizedBox()),
            Text(course.grade ?? "None", style: const TextStyle(color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
