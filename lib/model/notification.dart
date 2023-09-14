import 'package:isar/isar.dart';

part 'notification.g.dart';

@collection
class JupiterNotification {
  Id id = Isar.autoIncrement;

  DateTime? time;

  String? title;

  String? msg;
}
