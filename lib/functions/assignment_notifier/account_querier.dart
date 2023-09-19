import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/functions/setting_manager.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';

class JupiterAccountQuerier {
  static Future<void> ensureAccountNotNull() async {
    if (SettingManager.settings["jupiterName"] != null && SettingManager.settings["jupiterPassword"] != null) return;
    await updateAccount();
  }

  static Future<void> updateAccount() async {
    await Get.dialog(const JupiterAccountQueryDialog(), barrierDismissible: false);
    return;
  }
}

class JupiterAccountQueryDialog extends StatefulWidget {
  const JupiterAccountQueryDialog({super.key});

  @override
  State<JupiterAccountQueryDialog> createState() => _JupiterAccountQueryDialogState();
}

class _JupiterAccountQueryDialogState extends State<JupiterAccountQueryDialog> {
  final nameTextController = TextEditingController();
  final passwordTextController = TextEditingController();

  var loading = false;

  void saveAccount(Function func) async {
    setState(() => loading = true);

    final err = await SettingManager.jupiterAccount(nameTextController.text, passwordTextController.text);
    if (err == "success") {
      UI.showNotification("校验成功，已保存");
      func();
      return;
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      title: const Text("Jupiter 账号信息"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameTextController,
            decoration: const InputDecoration(hintText: "用户名/SID", prefixIcon: Icon(Icons.person)),
          ),
          TextField(
            controller: passwordTextController,
            obscureText: true,
            decoration: const InputDecoration(hintText: "密码", prefixIcon: Icon(Icons.lock)),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: loading ? null : () => saveAccount(() => Navigator.of(context).pop()),
          child: loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(value: null))
              : const Text("确认", style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}
