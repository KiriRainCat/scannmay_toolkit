import 'package:isar/isar.dart';

import 'package:scannmay_toolkit/model/jupiter.dart';

part 'notification.g.dart';

@collection
class JupiterNotification {
  Id id = 0;

  List<Message>? messages;
}

@embedded
class Message {
  int state = 0;

  DateTime? time;

  String? title;

  String? course;

  List<Assignment>? assignments;
}
