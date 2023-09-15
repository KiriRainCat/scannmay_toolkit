import 'dart:async';

import 'package:isar/isar.dart';
import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/model/notification.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/views/notification_view/notification_card.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/notification_queue.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Flex(
            direction: Axis.horizontal,
            children: [
              const ElevatedButton(onPressed: null, child: Text("前往 Jupiter Ed")),
              const Expanded(child: SizedBox()),
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
