import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';

class JupiterDataStatusBar extends StatelessWidget {
  const JupiterDataStatusBar({
    super.key,
    this.additionalWidgets,
  });

  final List<Widget>? additionalWidgets;

  void checkForAssignments() async {
    // 判断是否有浏览器正在进行数据检索，有的话不开始新的检索进程
    try {
      if (AssignmentNotifierBgWorker.browser.isConnected) {
        UI.showNotification("info4".tr);
        return;
      }
    } catch (_) {}

    UI.showNotification("info5".tr);
    AssignmentNotifierBgWorker.checkForNewAssignment();
  }

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: Axis.horizontal,
      children: [
        ElevatedButton(
          onPressed: () => Utils.openUrl("https://login.jupitered.com/login/"),
          child: Text("goToJupiter".tr),
        ),
        const SizedBox(width: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Tooltip(
                  verticalOffset: -45,
                  message: "dataFetchTimeTooltip".tr,
                  child: Obx(() => Text(AssignmentNotifierBgWorker.lastUpdateTime.value)),
                ),
                Obx(() {
                  if (AssignmentNotifierBgWorker.lastUpdateTime.value.isNotEmpty) {
                    return const SizedBox(width: 6);
                  } else {
                    return const SizedBox();
                  }
                }),
                Obx(() {
                  if (AssignmentNotifierBgWorker.dataFetchStatus.startsWith("+")) {
                    return Tooltip(
                      message: "dateFetchSuccess".tr,
                      child: const Icon(Icons.check_box, color: Colors.green),
                    );
                  } else if (AssignmentNotifierBgWorker.dataFetchStatus.startsWith(".")) {
                    return Tooltip(
                      message: "dataFetchInProgress".tr,
                      child: const Icon(Icons.wifi_protected_setup, color: Colors.blue),
                    );
                  } else {
                    return Tooltip(
                      message:
                          "${"dataFetchFailure".tr}: ${"\n"}${AssignmentNotifierBgWorker.dataFetchStatus.substring(1)}",
                      margin: const EdgeInsets.symmetric(horizontal: 256),
                      child: const Icon(Icons.nearby_error, color: Colors.red),
                    );
                  }
                }),
              ],
            ),
          ),
        ),
        const Expanded(child: SizedBox()),
        Tooltip(
          message: "forceFetchData".tr,
          child: ElevatedButton(
            onPressed: checkForAssignments,
            child: const Icon(Icons.refresh),
          ),
        ),
        ...additionalWidgets ?? [],
      ],
    );
  }
}
