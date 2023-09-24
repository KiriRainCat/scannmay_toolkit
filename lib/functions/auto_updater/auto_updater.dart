// ignore_for_file: use_build_context_synchronously

import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:ffi/ffi.dart';
import 'package:get/get.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

import 'package:scannmay_toolkit/main.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/functions/utils/logger.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';
import 'package:scannmay_toolkit/functions/auto_updater/update_notice_dialog.dart';

class AutoUpdater {
  ///? http 请求库 dio 的实例
  static final dio = Dio();

  ///? fetch 服务器上的 release.json 并比较版本 返回是否有更新
  static void checkForUpdate({bool atStartup = false}) async {
    const releaseJson = "https://www.kiriraincat.eu.org/061202/files/scannmay-toolkit/release.json";

    late final List releases;
    try {
      releases = (await dio.get(releaseJson)).data;
    } on DioException {
      Log.logger.e("远程服务器离线或网络错误");
      UI.showNotification("远程服务器离线或网络错误", type: NotificationType.error);
      return;
    }

    final String releaseVersion = releases[releases.length - 1]["version"];

    // 如果比较版本后发现有更新
    if (releaseVersion != version) {
      // 处理更新日志
      final List<String> releaseLogs = [];
      for (var i = releases.length - 1; i >= 0; i--) {
        if (releases[i]["version"] == version) break;
        releaseLogs.addAll(releases[i]["log"].split("\n"));
      }

      // 如果是启动时的自动更新，先显示窗口
      if (atStartup) {
        await windowManager.center();
        windowManager.show();
      }

      // 弹出更新提示框
      Get.dialog(
        UpdateNoticeDialog(releaseVer: releaseVersion, logs: releaseLogs),
        barrierDismissible: false,
      );
    } else if (!atStartup) {
      UI.showNotification("暂无更新");
    }
  }

  ///? 下载并更新软件
  static void updateSoftware(void Function(int received, int total) onReceiveProgress) async {
    // 第一时间先触发一次 progress 增加，避免用户多次点击更新
    onReceiveProgress(1, 1000);

    const setupFile = "ScannmayToolkit-Setup.exe";

    // 获取应用目录
    final path = "${Utils.getAppDir(true)}/$setupFile";

    const setupFileUrl = "https://www.kiriraincat.eu.org/061202/files/scannmay-toolkit/$setupFile";
    try {
      await dio.download(setupFileUrl, path, onReceiveProgress: onReceiveProgress);
    } on DioException {
      Log.logger.e("远程服务器离线或网络错误");
      UI.showNotification("远程服务器离线或网络错误", type: NotificationType.error);
      return;
    }

    // 执行 setup 文件
    ShellExecute(NULL, "open".toNativeUtf16(), path.toNativeUtf16(), nullptr, nullptr, SW_HIDE);

    // 终止当前应用
    Future.delayed(const Duration(seconds: 5));
    AssignmentNotifierBgWorker.forceStop();
    await windowManager.destroy();
  }
}
