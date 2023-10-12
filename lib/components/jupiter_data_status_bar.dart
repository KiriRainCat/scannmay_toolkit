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
    return Flex(
      direction: Axis.horizontal,
      children: [
        ElevatedButton(
          onPressed: () => Utils.openUrl("https://login.jupitered.com/login/"),
          child: const Text("前往 Jupiter"),
        ),
        const SizedBox(width: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Tooltip(
                  verticalOffset: -45,
                  message: "此时间为上次成功检索数据的时间 [如此次检索成功时间将为本次]",
                  child: Obx(() => Text(AssignmentNotifierBgWorker.lastUpdateTime.value)),
                ),
                const SizedBox(width: 6),
                Obx(() {
                  if (AssignmentNotifierBgWorker.dataFetchStatus.startsWith("+")) {
                    return const Tooltip(
                      message: "数据检索成功",
                      child: Icon(Icons.check_box, color: Colors.green),
                    );
                  } else if (AssignmentNotifierBgWorker.dataFetchStatus.startsWith(".")) {
                    return const Tooltip(
                      message: "数据检索中...",
                      child: Icon(Icons.wifi_protected_setup, color: Colors.blue),
                    );
                  } else {
                    return Tooltip(
                      message: "数据检索失败: ${"\n"}${AssignmentNotifierBgWorker.dataFetchStatus.substring(1)}",
                      margin: const EdgeInsets.symmetric(horizontal: 256),
                      child: const Icon(Icons.nearby_error, color: Colors.red),
                    );
                  }
                }),
              ],
            ),
          ),
        ),
        ...additionalWidgets ?? [],
      ],
    );
  }
}
