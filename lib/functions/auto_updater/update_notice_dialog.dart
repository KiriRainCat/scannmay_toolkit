import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/main.dart';
import 'package:scannmay_toolkit/functions/auth_manager.dart';
import 'package:scannmay_toolkit/components/unordered_list_item.dart';
import 'package:scannmay_toolkit/functions/auto_updater/auto_updater.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/notification_queue.dart';

class UpdateNoticeDialog extends StatefulWidget {
  const UpdateNoticeDialog({
    super.key,
    required this.releaseVer,
    required this.logs,
  });

  final String releaseVer;
  final List<String> logs;

  @override
  State<UpdateNoticeDialog> createState() => _UpdateNoticeDialogState();
}

class _UpdateNoticeDialogState extends State<UpdateNoticeDialog> {
  @override
  void initState() {
    // 处理更新日志中的特殊命令
    if (widget.logs.remove("Clear Database")) {
      NotificationQueue.clear();
      AssignmentNotifierBgWorker.clear();
    }
    if (widget.logs.remove("Logout")) AuthManager.logout(needEnsureLogging: false);

    super.initState();
  }

  // 下载进度
  var progress = 0.0;

  // 是否在进行下载
  bool ifDownloading() => progress != 0.0;

  // 更新下载进度的函数
  void onReceiveProgress(received, total) => setState(() => progress = received.toDouble() / total);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("updateNotice".tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Row(
              children: [
                Text("v$version", style: const TextStyle(color: Colors.grey)),
                const Text(" → "),
                Text("v${widget.releaseVer}", style: const TextStyle(color: Colors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 360,
            height: 256,
            child: ListView.builder(
              itemCount: widget.logs.length,
              itemBuilder: (context, index) => widget.logs[index].contains("!!!")
                  ? UnorderedListItem(text: widget.logs[index], textColor: Colors.red)
                  : UnorderedListItem(text: widget.logs[index]),
            ),
          ),
          // 在下载时显示进度条
          if (ifDownloading()) ...[
            const SizedBox(height: 16),
            Text("updating".tr, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              borderRadius: BorderRadius.circular(8),
            ),
          ]
        ],
      ),
      actions: [
        TextButton(
          onPressed: ifDownloading() ? null : () => AutoUpdater.updateSoftware(onReceiveProgress),
          child: Text("updateImmediately".tr),
        ),
        TextButton(
          onPressed: ifDownloading() ? null : () => Navigator.of(context).pop(false),
          child: Text("cancel".tr, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
