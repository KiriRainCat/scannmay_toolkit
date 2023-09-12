import 'package:isar/isar.dart';

part 'jupiter.g.dart';

@collection
class JupiterData {
  Id id = Isar.autoIncrement;

  List<Course>? courses;
}

@embedded
class Course {
  String? name;

  String? grade;

  int? gradedAssignmentCount;

  int? ungradedAssignmentCount;

  List<Assignment>? assignments;
}

@embedded
class Assignment {
  String? due;

  String? title;

  String? score;
}
