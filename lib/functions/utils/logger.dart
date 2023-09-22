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
      printTime: true,
      printEmojis: false,
      noBoxingByDefault: true,
    ),
  );

  static File _getLogFile() {
    final logPath = Directory("${Utils.getAppDir(true)}/logs");
    if (!logPath.existsSync()) logPath.createSync();

    final time = DateTime.now();
    final logFile = File("$logPath/${time.year}-${time.month}-${time.day}-logs.txt");

    if (!logFile.existsSync()) logFile.createSync();
    return logFile;
  }
}
