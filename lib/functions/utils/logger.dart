import 'dart:io';

import 'package:logger/logger.dart';

import 'package:scannmay_toolkit/functions/utils/utils.dart';

class Log {
  static final logger = Logger(
    filter: ProductionFilter(),
    level: Level.all,
    output: FileOutput(file: _getLogFile()),
    printer: PrettyPrinter(
      colors: false,
      methodCount: 0,
      lineLength: 60,
      printTime: true,
      levelEmojis: {
        Level.info: "Info:",
        Level.error: "Err:",
      },
    ),
  );

  static File _getLogFile() {
    final logPath = Directory("${Utils.getAppDir(true)}/logs");
    if (!logPath.existsSync()) logPath.createSync();

    final time = DateTime.now();
    final logFile = File("${logPath.path}/${time.year}-${time.month}-${time.day}-logs.txt");

    if (!logFile.existsSync()) logFile.createSync();
    _purgeLogFolder(logPath);
    return logFile;
  }

  static void _purgeLogFolder(Directory logPath) async {
    final logs = logPath.listSync();
    if (logs.length > 7) {
      for (var log in logs) {
        if (DateTime.now().difference((await log.stat()).changed).inDays > 7) {
          await log.delete();
        }
      }
    }
  }
}
