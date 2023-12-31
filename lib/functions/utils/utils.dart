import 'package:ffi/ffi.dart';
import 'package:isar/isar.dart';
import 'package:win32/win32.dart';

import 'package:process_run/process_run.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scannmay_toolkit/constants.dart';
import 'package:scannmay_toolkit/model/setting.dart';
import 'package:scannmay_toolkit/model/jupiter.dart';
import 'package:scannmay_toolkit/model/notification.dart';

class Utils {
  ///? Shell 系统命令行对象
  static Shell shell = Shell();

  ///? 初始化与连接数据库
  static Future<Isar> initDatabase() async {
    final isar = await Isar.open(
      [JupiterDataSchema, JupiterNotificationSchema, SettingSchema],
      directory: Utils.ifProduction() ? Utils.getAppDir(true) : Constants.devAppDir,
    );

    // 如果应用启动时数据库 消息队列 不存在，先创建一个避免页面报错
    if (isar.jupiterNotifications.filter().idEqualTo(0).findFirstSync() == null) {
      isar.writeTxn(() => isar.jupiterNotifications.put(JupiterNotification()..messages = []));
    }

    // 如果应用启动时数据库 Jupiter 信息 不存在，先创建一个避免页面报错
    if (isar.jupiterDatas.filter().idEqualTo(0).findFirstSync() == null) {
      isar.writeTxn(() => isar.jupiterDatas.put(JupiterData()..courses = []));
    }

    // 如果应用启动时数据库 默认设置 不存在，先创建一个避免页面报错
    if (isar.settings.countSync() == 0) {
      await isar.writeTxn(
        () => isar.settings.putAll(
          [
            Setting()
              ..name = "launchOnStartup" // 默认 开机自启 关
              ..value = "false",
            Setting()
              ..name = "jupiterDataFetchInterval" // 默认 Jupiter 数据检索间隔 10 min
              ..value = "10"
          ],
        ),
      );
    }

    return isar;
  }

  ///? 获取应用根目录 传入布尔决定是否移除最后的 exe 文件名
  static String getAppDir(bool removeExeName) {
    var path = GetCommandLine().toDartString();

    // 在生产环境下，去除路径中杂七杂八的传参，只保留路径
    if (ifProduction()) path = RegExp(r'"([^"]*)"').firstMatch(path)!.group(1)!;
    if (!removeExeName) return path;

    // 需要移除 exe 名称的话
    return removeLastFromPath(path)[0];
  }

  ///? 删除文件路径中的最后一个 \ 后的内容，返回保留内容 [0] & 被删除的内容 [1]
  static List removeLastFromPath(String path) {
    final pathSegments = path.split("\\");
    final last = pathSegments.removeLast();
    return [pathSegments.join("/"), last];
  }

  ///? 查看应用是否处于生产环境
  static bool ifProduction() {
    return const bool.fromEnvironment("dart.vm.product");
  }

  ///? 格式化 DateTime 为人能读的 String
  static String formatTime(DateTime time) {
    var parts = <dynamic>[];
    parts.addAll([time.month, time.day, time.hour, time.minute, time.second]);
    parts = parts.map((e) {
      if (e < 10) return e = "0$e";
      return e;
    }).toList();
    return "${time.year}-${parts[0]}-${parts[1]} ${parts[2]}:${parts[3]}:${parts[4]}";
  }

  ///? 格式化并输出 DueDate 字符串
  static String formatDueDate(String? raw) {
    if (raw == null || raw.isEmpty) return "00/00";
    final parts = raw.split("-");
    parts.removeAt(0);
    if (parts[0].length < 2) parts[0] = "0${parts[0]}";
    if (parts[1].length < 2) parts[1] = "0${parts[1]}";
    return parts.join("/");
  }

  ///? 通过用户默认浏览器打开指定 URL
  static void openUrl(String url) {
    launchUrl(Uri.parse(url));
  }
}
