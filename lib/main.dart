import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:window_manager/window_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:windows_single_instance/windows_single_instance.dart';

import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/functions/auth_manager.dart';
import 'package:scannmay_toolkit/views/global_nav/global_nav_view.dart';
import 'package:scannmay_toolkit/functions/setting_manager/manager.dart';
import 'package:scannmay_toolkit/functions/auto_updater/auto_updater.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/notification_queue.dart';
import 'package:scannmay_toolkit/functions/setting_manager/jupiter_account_querier.dart';

late final String version;

void main(List<String> args) async {
  // 获取版本号
  version = (await PackageInfo.fromPlatform()).version;

  // 初始化与启动应用
  await _initAndRunApp(args);

  // 开启数据库
  final isar = await Utils.initDatabase();

  // 从数据库获取用户设置
  await SettingManager.init(isar);

  // 确保用户已登录
  await AuthManager.ensureLoggedIn();

  // 确保初次启动时用户输入 Jupiter 账号信息
  await JupiterAccountQuerier.ensureAccountNotNull();

  // 启动 Jupiter 数据定时获取进程
  AssignmentNotifierBgWorker.initAndStart(
    db: isar,
    immediate: true,
    SettingManager.settings["jupiterDataFetchInterval"]!,
  );

  // 启动消息队列数据库
  NotificationQueue.initQueue(isar);

  // 应用启动时检查更新
  if (Utils.ifProduction()) AutoUpdater.checkForUpdate(atStartup: true);
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      decoration: const BoxDecoration(borderRadius: BorderRadius.all(Radius.circular(16))),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          fontFamily: "SourceHanSansSC",
        ),
        home: const GlobalNavView(),
      ),
    );
  }

  @override
  void onWindowClose() {
    windowManager.hide();
  }
}

Future<void> _initAndRunApp(List<String> args) async {
  // 必须的初始化工作
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await localNotifier.setup(appName: "Scannmay Toolkit");

  // 单例模式判断
  await WindowsSingleInstance.ensureSingleInstance(
    args,
    "desktop_open",
    onSecondWindow: (args) async {
      if (await windowManager.isMinimized()) await windowManager.restore();
      _showWindow();
    },
  );

  // 窗口属性初始化
  windowManager.waitUntilReadyToShow(
    const WindowOptions(
      title: "Scannmay Toolkit",
      size: Size(820, 680),
      titleBarStyle: TitleBarStyle.hidden,
    ),
    () async {
      await windowManager.setAsFrameless();
      await windowManager.setPreventClose(true);
      await windowManager.setBackgroundColor(Colors.transparent);
    },
  );

  // 系统托盘相关设置
  final systemTray = SystemTray();
  await systemTray.initSystemTray(
    iconPath: Platform.isWindows ? 'assets/images/tray_icon.ico' : 'assets/images/tray_icon.png',
  );

  // 注册系统托盘菜单
  Menu menu = Menu();
  await menu.buildFrom([
    MenuItemLabel(label: "关闭应用", onClicked: (menuItem) => windowManager.destroy()),
  ]);
  await systemTray.setContextMenu(menu);

  // 注册系统托盘事件
  systemTray.registerSystemTrayEventHandler((eventName) async {
    if (eventName == kSystemTrayEventClick) {
      _showWindow();
    } else if (eventName == kSystemTrayEventRightClick) {
      systemTray.popUpContextMenu();
    }
  });

  // 注册快捷键
  await hotKeyManager.unregisterAll();
  await hotKeyManager.register(
    // 全局快捷键：显示与隐藏应用界面 默认 Ctrl + Alt + N
    HotKey(
      KeyCode.keyN,
      identifier: "switchWindowVisibleState",
      modifiers: [KeyModifier.control, KeyModifier.alt],
    ),
    keyDownHandler: (hotKey) async {
      switch (hotKey.identifier) {
        case "switchWindowVisibleState":
          if (await windowManager.isFocused()) {
            windowManager.hide();
          } else {
            _showWindow();
          }
          break;
      }
    },
  );

  // 启动应用
  runApp(const MainApp());

  // 开机启动不显示窗口，显示系统消息，反之显示窗口
  if (args.contains("-startup")) {
    final notification = LocalNotification(
      title: "软件已启动并隐藏至系统托盘",
      actions: [LocalNotificationAction(text: "显示窗口")],
    );
    notification.onClickAction = (index) => _showWindow();
    notification.show();
  } else {
    _showWindow();
  }
}

void _showWindow() async {
  await windowManager.center();
  windowManager.show();
  windowManager.focus();
}
