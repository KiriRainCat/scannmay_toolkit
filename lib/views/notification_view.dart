import 'package:flutter/material.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("第一次进行查询时可能会较慢，需要下载 Chromium 核心"),
        SizedBox(height: 12),
        ElevatedButton(
          onPressed: AssignmentNotifierBgWorker.initAndStart,
          child: Text("启动数据库"),
        ),
        SizedBox(height: 12),
        ElevatedButton(
          onPressed: AssignmentNotifierBgWorker.checkForNewAssignment,
          child: Text("分析 Jupiter 信息"),
        ),
      ],
    );
  }
}
