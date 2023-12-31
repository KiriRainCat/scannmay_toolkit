import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:win32_registry/win32_registry.dart';

import 'package:scannmay_toolkit/model/setting.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/functions/utils/logger.dart';
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
      if (err != "success") msg += "$err\n";
    }

    if (msg.isNotEmpty) {
      Log.logger.e("${"err5".tr}: $msg");
      UI.showNotification(msg.substring(0, msg.length - 1));
    } else {
      UI.showNotification("saveSuccess".tr);
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
    settings["launchOnStartup"] = flag.toString();
    final setting = await isar.settings.filter().nameEqualTo("launchOnStartup").findFirst();
    isar.writeTxn(() => isar.settings.put(setting!..value = flag.toString()));
  }

  static Future<String> jupiterAccount(String name, String password) async {
    if (name.isEmpty || password.isEmpty) {
      UI.showNotification("Jupiter ID/用户名 或密码不得为空", type: NotificationType.error);
      return "";
    }

    // 检查账号密码是否可用
    final page = await AssignmentNotifierBgWorker.openJupiterPage();
    if (page == null) return "";
    if (!(await AssignmentNotifierBgWorker.login(page, name: name, password: password))) return "";

    settings["jupiterName"] = name;
    settings["jupiterPassword"] = password;

    // 写入数据库
    var jupiterName = await isar.settings.filter().nameEqualTo("jupiterName").findFirst();
    var jupiterPwd = await isar.settings.filter().nameEqualTo("jupiterPassword").findFirst();

    jupiterName ??= Setting()..name = "jupiterName";
    jupiterPwd ??= Setting()..name = "jupiterPassword";

    isar.writeTxn(() => isar.settings.put(jupiterName!..value = name));
    isar.writeTxn(() => isar.settings.put(jupiterPwd!..value = password));

    return "success";
  }

  ///? 删除或写入 loginToken 设置值，如果 token 未传入，进行删除操作
  static Future<void> loginToken({String? token}) async {
    var loginTokenSetting = await isar.settings.filter().nameEqualTo("loginToken").findFirst();
    loginTokenSetting ??= Setting()
      ..name = "loginToken"
      ..value = token;

    if (token == null) {
      isar.writeTxn(() => isar.settings.delete(loginTokenSetting!.id));
      settings.remove("loginToken");
      return;
    }

    settings["loginToken"] = token;
    isar.writeTxn(() => isar.settings.put(loginTokenSetting!));
  }

  static Future<void> cfCookieStr() async {
    final controller = TextEditingController(text: settings["cfCookieStr"]);
    await Get.dialog<String?>(
      AlertDialog(
        title: const Text("Cloudflare Bypass Cookies"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: "cookieString".tr, prefixIcon: const Icon(Icons.cookie)),
        ),
      ),
    );

    if (controller.text.isEmpty || controller.text == settings["cfCookieStr"]) {
      UI.showNotification("err1".tr, type: NotificationType.error);
      return;
    }
    controller.text = controller.text.replaceAll(RegExp("\n"), "");

    // 空捕捉，并写入数据库
    settings["cfCookieStr"] = controller.text;
    final setting = await isar.settings.filter().nameEqualTo("cfCookieStr").findFirst() ?? Setting()
      ..name = "cfCookieStr";
    isar.writeTxn(() => isar.settings.put(setting..value = controller.text));
  }

  static Future<void> locale(Locale locale) async {
    // 更新语言
    Get.updateLocale(locale);
    // 写入数据库
    final setting = await isar.settings.filter().nameEqualTo("locale").findFirst() ?? Setting()
      ..name = "locale";
    isar.writeTxn(() => isar.settings.put(setting..value = locale.toString()));
  }

  //* ------------------------------- 需要保存生效的设置 ------------------------------ *//
  static Future<String> jupiterDataFetchInterval(int interval) async {
    if (interval < 10 || interval > 120) return "${"err2".tr}：$interval";
    settings["jupiterDataFetchInterval"] = interval.toString();

    // 重启 Jupiter 数据检索 后台进程
    AssignmentNotifierBgWorker.bgWorker.cancel();
    AssignmentNotifierBgWorker.initAndStart(settings["jupiterDataFetchInterval"]!);

    // 写入数据库
    final setting = await isar.settings.filter().nameEqualTo("jupiterDataFetchInterval").findFirst();
    isar.writeTxn(() => isar.settings.put(setting!..value = interval.toString()));

    return "success";
  }
}
