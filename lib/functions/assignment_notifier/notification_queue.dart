import 'package:isar/isar.dart';

import 'package:scannmay_toolkit/model/notification.dart';

class NotificationQueue {
  static late final Isar isar;

  static void initQueue(Isar db) {
    isar = db;
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
