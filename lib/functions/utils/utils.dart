import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

class Utils {
  ///? 传入 seconds 转换为 小时:分钟:秒 的格式 Ex. (03:13:09)
  static String formatSeconds(int sec) {
    dynamic hours = (sec / 3600).floor();
    hours = "${hours < 10 ? "0" : ""}$hours";

    dynamic minutes = (sec % 3600 / 60).floor();
    minutes = "${minutes < 10 ? "0" : ""}$minutes";

    dynamic seconds = (sec % 60);
    seconds = "${seconds < 10 ? "0" : ""}$seconds";

    return "$hours:$minutes:$seconds";
  }

  ///? 获取当前日期 Ex. (2023-8-17)
  static String getDateString() {
    final date = DateTime.now();
    return "${date.year}-${date.month}-${date.day}";
  }

  ///? 获取应用根目录 传入布尔决定是否移除最后的 exe 文件名
  static String getAppDir(bool removeExeName) {
    var path = GetCommandLine().toDartString();

    // 在生产环境下，去除路径中杂七杂八的传参，只保留路径
    if (ifProduction()) path = RegExp(r'"([^"]*)"').firstMatch(path)!.group(1)!;
    if (!removeExeName) return path;

    // 需要移除 exe 名称的话
    return removeLastFromPath(path)[0];
  }

  ///? 删除文件路径中的最后一个 \ 后的内容，返回保留内容 [0] & 被删除的内容 [1]
  static List removeLastFromPath(String path) {
    final pathSegments = path.split("\\");
    final last = pathSegments.removeLast();
    return [pathSegments.join("/"), last];
  }

  ///? 查看应用是否处于生产环境
  static bool ifProduction() {
    return const bool.fromEnvironment("dart.vm.product");
  }
}
