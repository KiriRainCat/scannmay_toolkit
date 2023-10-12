import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';

class JupiterDataStatusBar extends StatelessWidget {
  const JupiterDataStatusBar({
    super.key,
    this.additionalWidgets,
  });

  final List<Widget>? additionalWidgets;

  @override
  Widget build(BuildContext context) {
    final RxString lastUpdatedTime = AssignmentNotifierBgWorker.lastUpdateTime;

    return Flex(
      direction: Axis.horizontal,
      children: [
        ElevatedButton(
          onPressed: () => Utils.openUrl("https://login.jupitered.com/login/"),
          child: const Text("前往 Jupiter"),
        ),
        const SizedBox(width: 16),
        Obx(() => Text("上次数据更新于: $lastUpdatedTime")),
        ...additionalWidgets ?? [],
      ],
    );
  }
}
