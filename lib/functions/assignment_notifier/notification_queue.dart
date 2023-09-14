import 'package:isar/isar.dart';

import 'package:scannmay_toolkit/model/notification.dart';

class NotificationQueue {
  static late final Isar isar;

  static void initQueue(Isar db) {
    isar = db;
  }

  static void push(Message msg) async {
    var notificationQueue = await isar.jupiterNotifications.filter().idEqualTo(0).findFirst();
    notificationQueue ??= JupiterNotification()..messages = [msg];

    notificationQueue.messages = notificationQueue.messages!.toList()..add(msg);
    isar.writeTxn(() => isar.jupiterNotifications.put(notificationQueue!));
  }

  static void pop(int index) async {
    final notificationQueue = await isar.jupiterNotifications.filter().idEqualTo(0).findFirst();
    notificationQueue!.messages = notificationQueue.messages!.toList()..removeAt(index);
    isar.writeTxn(() => isar.jupiterNotifications.put(notificationQueue));
  }

  static void clear() async {
    final notificationQueue = await isar.jupiterNotifications.filter().idEqualTo(0).findFirst();
    notificationQueue!.messages = notificationQueue.messages!.toList()..removeWhere((_) => true);
    isar.writeTxn(() => isar.jupiterNotifications.put(notificationQueue));
  }
}
