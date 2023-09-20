import 'package:get/get.dart';
import 'package:flutter/material.dart';

class UI {
  ///? 在顶部弹出一个提示框
  static SnackbarController showNotification(
    String message, {
    NotificationType type = NotificationType.info,
  }) {
    // 根据消息框类型决定图标，背景色，字体色
    late final Icon icon;

    switch (type) {
      case NotificationType.error:
        icon = Icon(Icons.error, color: Colors.red.shade600);
        break;
      default:
        icon = Icon(Icons.info, color: Colors.blue.shade600);
    }

    return Get.snackbar(
      "null",
      "null",
      barBlur: 0,
      backgroundColor: Colors.white70,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      duration: const Duration(milliseconds: 1800),
      animationDuration: const Duration(milliseconds: 500),
      maxWidth: 360,
      titleText: const SizedBox(height: 0),
      messageText: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ///? 弹出一个居中的确认框
  static Future<bool> queryUserConfirm(String title, String msg) async {
    var result = await Get.dialog<bool>(_ConfirmDialog(title, msg));
    return result ??= false;
  }
}

///? 提示框类型
enum NotificationType {
  info,
  error,
}

///? 确认弹窗
class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog(
    this.title,
    this.msg,
  );

  final String title;
  final String msg;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("确认", style: TextStyle(color: Colors.red)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("取消", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
