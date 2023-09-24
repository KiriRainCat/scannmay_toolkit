import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import 'package:scannmay_toolkit/constants.dart';
import 'package:scannmay_toolkit/model/jupiter.dart';
import 'package:scannmay_toolkit/model/notification.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/functions/utils/logger.dart';
import 'package:scannmay_toolkit/components/rounded_button.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/notification_queue.dart';

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

  void fetchAssignmentDesc(String assignmentTitle) async {
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
      if (await courses[i].evaluate("node => node.innerText") == message.course) {
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
      UI.showNotification("Chromium 自动化浏览器出现上下文异常，作业详情信息获取失败: $e", type: NotificationType.error);
      AssignmentNotifierBgWorker.browser.close();
      return;
    }

    // 获取数据库数据
    final jupiterData = (await AssignmentNotifierBgWorker.isar.jupiterDatas.filter().idEqualTo(0).findFirst())!;
    final course = jupiterData.courses!.firstWhere((course) => course.name == message.course);
    final assignments = [Assignment()..title = assignmentTitle];

    // 查询作业详情并写入数据库
    await AssignmentNotifierBgWorker.getAssignmentDesc(jupiterPage, course, assignments);
    AssignmentNotifierBgWorker.isar.writeTxn(() => AssignmentNotifierBgWorker.isar.jupiterDatas.put(jupiterData));

    AssignmentNotifierBgWorker.browser.close();
    Log.logger.i("浏览器关闭");
    UI.showNotification("$assignmentTitle 的数据检索完成啦，重新打开详情页以查看信息");
  }

  void showAssignmentInfo(Assignment assignment) async {
    final data = await AssignmentNotifierBgWorker.isar.jupiterDatas.filter().idEqualTo(0).findFirst();
    final course = data!.courses!.firstWhere((course) => course.name == message.course);
    var desc = course.assignments!.firstWhere((item) => item.title == assignment.title).desc;

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
                      Text("From: ${message.course}"),
                      const SizedBox(height: 4),
                      Text("Due: ${formatDueDate(assignment.due!)}"),
                      const SizedBox(height: 4),
                      Text("Score: [ ${assignment.score} ]"),
                      const SizedBox(height: 16),
                      const Text("Directions: ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(desc),
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
      padding: const EdgeInsets.all(8),
      foregroundDecoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: message.title == "新作业提示" ? Colors.green.shade400 : Colors.blue.shade300,
            width: 10,
          ),
        ),
      ),
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
          const SizedBox(width: 12),
          Expanded(
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
                    const SizedBox(width: 24),
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
                      const SizedBox(width: 4),
                      Column(
                        children: [
                          const SizedBox(height: 2),
                          RoundedButton(
                            width: 16,
                            height: 16,
                            onPressed: () => showAssignmentInfo(assignment),
                            buttonContent: const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
          IconButton(
            onPressed: () => NotificationQueue.pop(message),
            icon: const Icon(Icons.close),
            tooltip: "移除",
          ),
        ],
      ),
    );
  }
}
