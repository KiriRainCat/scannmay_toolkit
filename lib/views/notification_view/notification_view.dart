import 'dart:async';

import 'package:isar/isar.dart';
import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/model/notification.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/components/jupiter_data_status_bar.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';
import 'package:scannmay_toolkit/views/notification_view/notification_card.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/notification_queue.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => NotificationViewState();
}

class NotificationViewState extends State<NotificationView> {
  final isar = NotificationQueue.isar;

  late JupiterNotification notificationQueue;
  late final StreamSubscription<JupiterNotification?> notificationStreamListener;

  @override
  void initState() {
    notificationQueue = isar.jupiterNotifications.filter().idEqualTo(0).findFirstSync()!
      ..messages!.sort(
        (a, b) => b.time!.compareTo(a.time!),
      );
    watchMessageQueue();
    super.initState();
  }

  @override
  void dispose() {
    notificationStreamListener.cancel();
    super.dispose();
  }

  void watchMessageQueue() {
    final notificationStream = isar.jupiterNotifications.watchObject(0);
    notificationStreamListener = notificationStream.listen(
      (newNotificationQueue) => setState(
        () => notificationQueue = newNotificationQueue!
          ..messages!.sort(
            (a, b) => b.time!.compareTo(a.time!),
          ),
      ),
    );
  }

  void clearNotificationQueue() async {
    final result = await UI.queryUserConfirm("提示", "确定要清空消息队列吗？");
    if (result) NotificationQueue.clear();
  }

  void checkForAssignments() async {
    // 判断是否有浏览器正在进行数据检索，有的话不开始新的检索进程
    try {
      if (AssignmentNotifierBgWorker.browser.isConnected) {
        UI.showNotification("已有浏览器正在检索数据");
        return;
      }
    } catch (_) {}

    UI.showNotification("数据检索已开始，请耐心等待");
    AssignmentNotifierBgWorker.checkForNewAssignment();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          JupiterDataStatusBar(
            additionalWidgets: [
              const Expanded(child: SizedBox()),
              Tooltip(
                message: "强制重新检索数据",
                child: ElevatedButton(
                  onPressed: checkForAssignments,
                  child: const Icon(Icons.refresh),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: clearNotificationQueue,
                child: const Text("清空队列", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < notificationQueue.messages!.length; i++) ...[
                    NotificationCard(message: notificationQueue.messages![i]),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
