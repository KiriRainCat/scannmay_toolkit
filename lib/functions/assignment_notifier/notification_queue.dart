import 'package:isar/isar.dart';

import 'package:scannmay_toolkit/constants.dart';
import 'package:scannmay_toolkit/model/notification.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';

class NotificationQueue {
  static late final Isar isar;

  static void initQueue() async {
    isar = await Isar.open(
      [JupiterNotificationSchema],
      directory: Utils.ifProduction() ? Utils.getAppDir(true) : Constants.devAppDir,
    );
  }

  static void push(JupiterNotification notification) {
    isar.writeTxn(() => isar.jupiterNotifications.put(notification));
  }

  static void pop(int id) {
    isar.writeTxn(() => isar.jupiterNotifications.delete(id));
  }

  static void clear() {
    isar.writeTxn(() => isar.jupiterNotifications.clear());
  }
}
