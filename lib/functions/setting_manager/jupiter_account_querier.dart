import 'package:get/get.dart';
import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/setting_manager/manager.dart';

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
      UI.showNotification("verifiedSaved".tr);
      func();
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      title: Text("jupiterAccountInfo".tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameTextController,
            decoration: InputDecoration(hintText: "usernameOrSid".tr, prefixIcon: const Icon(Icons.person)),
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
          onPressed: loading ? null : () => saveAccount(() => Navigator.of(context).pop()),
          child: loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator())
              : Text("confirm".tr, style: const TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }
}
