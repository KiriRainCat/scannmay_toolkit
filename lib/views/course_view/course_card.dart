import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/constants.dart';
import 'package:scannmay_toolkit/model/jupiter.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/logger.dart';
import 'package:scannmay_toolkit/components/rounded_button.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
  });

  final Course course;

  String formatDueDate(String raw) {
    if (raw.isEmpty) return "00/00";
    final parts = raw.split("/");
    if (parts[0].length < 2) parts[0] = "0${parts[0]}";
    if (parts[1].length < 2) parts[1] = "0${parts[1]}";
    return parts.join("/");
  }

  void showCourseInfo(BuildContext context) {
    final courses = AssignmentNotifierBgWorker.isar.jupiterDatas.filter().idEqualTo(0).findFirstSync()!.courses!;
    final assignments = courses.firstWhere((item) => item.name == course.name).assignments!
      ..sort(
        (a, b) {
          if (a.due == null || a.due!.isEmpty) return 1;
          if (b.due == null || b.due!.isEmpty) return 1;

          final dateArr1 = a.due!.split("/");
          final dateArr2 = b.due!.split("/");

          final dueA = DateTime(0, int.parse(dateArr1[0]), int.parse(dateArr1[1]));
          final dueB = DateTime(0, int.parse(dateArr2[0]), int.parse(dateArr2[1]));

          return dueB.compareTo(dueA);
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
                                formatDueDate(assignment.due!),
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
    UI.showNotification("请等待数据检索完成的提示信息，期间请不要重复点击检索数据按钮");

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
      Log.logger.e("浏览器关闭", error: e);
      AssignmentNotifierBgWorker.lastUpdateTime.value.replaceAll(RegExp(r" (数据检索中...)"), "数据检索失败");
      UI.showNotification("Chromium 自动化浏览器出现上下文异常，作业详情信息获取失败: $e", type: NotificationType.error);
      AssignmentNotifierBgWorker.browser.close();
      return;
    }

    // 获取数据库数据
    final jupiterData = (await AssignmentNotifierBgWorker.isar.jupiterDatas.filter().idEqualTo(0).findFirst())!;
    final c = jupiterData.courses!.firstWhere((item) => item.name == course.name);
    final assignments = [Assignment()..title = assignmentTitle];

    // 查询作业详情并写入数据库
    await AssignmentNotifierBgWorker.getAssignmentDesc(jupiterPage, c, assignments);
    AssignmentNotifierBgWorker.isar.writeTxn(() => AssignmentNotifierBgWorker.isar.jupiterDatas.put(jupiterData));

    AssignmentNotifierBgWorker.browser.close();
    Log.logger.i("浏览器关闭");
    UI.showNotification("$assignmentTitle 的数据检索完成啦，重新打开详情页以查看信息");
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
                      Text("Due: ${formatDueDate(assignment.due!)}"),
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
