import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:scannmay_toolkit/constants.dart';

import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/logger.dart';
import 'package:scannmay_toolkit/functions/setting_manager/manager.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/bg_worker.dart';

class AuthManager {
  static final dio = Dio(
    BaseOptions(
      baseUrl: "https://scannmay-toolkit.kiriraincat.eu.org/api",
      headers: {"Authorization": Constants.appAuthToken},
    ),
  );

  static Future<void> ensureLoggedIn() async {
    if (SettingManager.settings["loginToken"] != null) return;
    await Get.dialog(const UserAuthDialog(), barrierDismissible: false);
  }

  static Future<bool> login(String name, String password) async {
    late final Response res;
    try {
      res = await dio.post("/auth/login", queryParameters: {"name": name, "password": password});
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        UI.showNotification(e.response?.data["msg"], type: NotificationType.error);
        return false;
      }

      Log.logger.e("err4".tr);
      UI.showNotification("err4".tr, type: NotificationType.error);
      return false;
    }

    UI.showNotification(res.data["msg"]);
    await SettingManager.loginToken(token: res.data["data"]);
    return true;
  }

  static void logout({bool needEnsureLogging = true}) async {
    late final Response res;
    try {
      res = await dio.post("/auth/logout", queryParameters: {"token": SettingManager.settings["loginToken"]});
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        UI.showNotification(e.response?.data["msg"], type: NotificationType.error);
      }

      Log.logger.e("err4".tr);
      UI.showNotification("err4".tr, type: NotificationType.error);
    }

    UI.showNotification(res.data["msg"]);
    await SettingManager.loginToken();
    AssignmentNotifierBgWorker.forceStop();
    if (needEnsureLogging) ensureLoggedIn();
  }
}

class UserAuthDialog extends StatefulWidget {
  const UserAuthDialog({super.key});

  @override
  State<UserAuthDialog> createState() => _UserAuthDialogState();
}

class _UserAuthDialogState extends State<UserAuthDialog> {
  final nameTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  var loading = false;

  void login(Function func) async {
    setState(() => loading = true);

    if (await AuthManager.login(nameTextController.text, passwordTextController.text)) func();

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      title: Text("pleaseLogin".tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameTextController,
            decoration: InputDecoration(hintText: "usernameOrEmail".tr, prefixIcon: const Icon(Icons.person)),
          ),
          TextField(
            controller: passwordTextController,
            obscureText: true,
            decoration: InputDecoration(hintText: "password".tr, prefixIcon: const Icon(Icons.lock)),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: loading ? null : () => login(() => Navigator.of(context).pop()),
          child: loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
              : Text("login".tr, style: const TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}
