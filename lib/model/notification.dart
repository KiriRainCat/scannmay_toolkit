import 'package:isar/isar.dart';

import 'package:scannmay_toolkit/model/jupiter.dart';

part 'notification.g.dart';

@collection
class JupiterNotification {
  Id id = Isar.autoIncrement;

  DateTime? time;

  String? title;

  List<Assignment>? assignments;
}
