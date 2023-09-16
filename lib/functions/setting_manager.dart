import 'package:isar/isar.dart';
import 'package:win32_registry/win32_registry.dart';

import 'package:scannmay_toolkit/model/setting.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';

class SettingManager {
  static late final Isar isar;

  static late final Map<String, String> settings;

  static Future<void> init(Isar db) async {
    isar = db;
    final storedSettings = await isar.settings.filter().idGreaterThan(-1).findAll();

    settings = {};
    for (var kv in storedSettings.map((e) => {e.name: e.value})) {
      settings.addAll(kv.cast());
    }
  }

  static void saveSettings(Map<String, String> newSettings) async {
    final errors = [
      await jupiterDataFetchInterval(int.parse(newSettings["jupiterDataFetchInterval"]!)),
    ];

    var msg = "";
    for (var err in errors) {
      if (err.isNotEmpty) msg += "$err\n";
    }

    if (msg.isNotEmpty) {
      UI.showNotification(msg.substring(0, msg.length - 1));
    } else {
      UI.showNotification("保存成功");
    }
  }

  //* ------------------------------- 无需保存生效的设置 ------------------------------ *//
  static void launchOnStartup(bool flag) async {
    // 注册表 Key
    final key = Registry.openPath(RegistryHive.currentUser,
        path: r"SOFTWARE\Microsoft\Windows\CurrentVersion\Run", desiredAccessRights: AccessRights.allAccess);

    // 开关开机自启
    if (flag) {
      final currentValue = key.getValueAsString("Scannmay Toolkit");
      final targetVal = '"${Utils.getAppDir(false)}" "-startup"';

      if (currentValue != targetVal) {
        key.createValue(RegistryValue("Scannmay Toolkit", RegistryValueType.string, targetVal));
      }
    } else {
      key.deleteValue("Scannmay Toolkit");
    }

    // 写入数据库
    final setting = await isar.settings.filter().nameEqualTo("launchOnStartup").findFirst();
    isar.writeTxn(() => isar.settings.put(setting!..value = flag.toString()));
  }

  //* ------------------------------- 需要保存生效的设置 ------------------------------ *//
  static Future<String> jupiterDataFetchInterval(int interval) async {
    if (interval < 10 || interval > 120) return "数据检索间隔不合法：$interval";
    settings["jupiterDataFetchInterval"] = interval.toString();

    // 重启 Jupiter 数据检索 后台进程
    AssignmentNotifierBgWorker.bgWorker.cancel();
    AssignmentNotifierBgWorker.initAndStart(settings["jupiterDataFetchInterval"]!);

    // 写入数据库
    final setting = await isar.settings.filter().nameEqualTo("jupiterDataFetchInterval").findFirst();
    isar.writeTxn(() => isar.settings.put(setting!..value = interval.toString()));

    return "";
  }
}
