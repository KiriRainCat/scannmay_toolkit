import 'package:flutter/material.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';

class NotificationView extends StatelessWidget {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("第一次进行查询时可能会较慢，需要下载 Chromium 核心"),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => AssignmentNotifierBgWorker.checkForNewAssignment(),
          child: const Text("分析 Jupiter 信息"),
        ),
      ],
    );
  }
}
