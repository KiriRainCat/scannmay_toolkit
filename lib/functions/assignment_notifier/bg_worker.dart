// cSpell: disable

import 'dart:math';
import 'dart:async';

import 'package:get/get.dart';
import 'package:isar/isar.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:local_notifier/local_notifier.dart';

import 'package:scannmay_toolkit/constants.dart';
import 'package:scannmay_toolkit/model/jupiter.dart';
import 'package:scannmay_toolkit/model/notification.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/functions/utils/logger.dart';
import 'package:scannmay_toolkit/functions/setting_manager/manager.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/notification_queue.dart';

class AssignmentNotifierBgWorker {
  static late final Isar isar;

  static late Timer bgWorker;

  static var lastUpdateTime = "".obs;

  /// . 开头为检索中; + 开头为成功; - 开头为失败，后面有失败原因
  static var dataFetchStatus = ".".obs;

  static late Browser browser;

  static void initAndStart(String dataFetchInterval, {Isar? db}) async {
    if (db != null) isar = db;
    await Future.delayed(Constants.universalDelay);
    bgWorker = Timer.periodic(Duration(minutes: int.parse(dataFetchInterval)), (_) => checkForNewAssignment());
  }

  static void forceStop() async {
    try {
      AssignmentNotifierBgWorker.bgWorker.cancel();
      await AssignmentNotifierBgWorker.closeBrowser();
    } catch (_) {}
  }

  static void clear() async {
    final jupiterData = await isar.jupiterDatas.filter().idEqualTo(0).findFirst();
    jupiterData!.courses = jupiterData.courses!.toList()..removeWhere((_) => true);
    isar.writeTxn(() => isar.jupiterDatas.put(jupiterData));
  }

  static Future<void> closeBrowser() async {
    browser.close();
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      Utils.shell.run("taskkill /f /t /im chrome.exe");
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 100));
  }

  static Future<Page?> openJupiterPage() async {
    await Future.delayed(Duration(milliseconds: Random().nextInt(500) + 100));

    // 如果浏览器对象已经存在，等待最长 120s
    var secondsWaited = 0;
    for (var i = 0; i < 120; i++) {
      secondsWaited++;
      try {
        if (browser.isConnected) {
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        break;
      } catch (_) {
        break;
      }
    }
    if (secondsWaited > 119) {
      Log.logger.e("浏览器启动失败", error: "等待 120s 后上一个浏览器对象仍然存在");
      return null;
    }

    dataFetchStatus.value = ".";

    // 创建浏览器对象，根据环境决定是否使用无头模式
    late final Page jupiterPage;
    try {
      browser = await puppeteer.launch(
        headless: Utils.ifProduction() ? true : false,
        defaultViewport: null,
      );
      jupiterPage = await browser.newPage();

      //* --------------------------------- 绕过反爬 --------------------------------- *//
      await jupiterPage.setUserAgent(Constants.userAgent);

      await jupiterPage.evaluateOnNewDocument(
          "const newProto = navigator.__proto__;delete newProto.webdriver;navigator.__proto__ = newProto;");

      // Cookie 绕过 Cloudflare 反爬
      final cookies = <CookieParam>[];
      for (var cookie in SettingManager.settings["cfCookieStr"]?.split("; ") ?? []) {
        if (cookie.contains("cf")) {
          cookies.add(CookieParam(name: cookie.split("=")[0], value: cookie.split("=")[1], domain: ".jupitered.com"));
        }
      }
      await Future.delayed(Constants.universalDelay);
      await jupiterPage.setCookies(cookies);

      Log.logger.i("浏览器启动");
    } catch (e) {
      await closeBrowser();
      Log.logger.e("browserClose".tr, error: e);
      final error = "Chromium 自动化浏览器启动异常: $e";
      dataFetchStatus.value = "-$error";
      UI.showNotification(error, type: NotificationType.error);
      return null;
    }

    // 前往 Jupiter 登录页
    var timesOfErr = 0;
    for (var i = 0; i < 4; i++) {
      try {
        await jupiterPage.goto("https://login.jupitered.com/login/", wait: Until.networkIdle);
        await jupiterPage.waitForSelector("#text_school1");
        await Future.delayed(Constants.universalDelay);
        break;
      } catch (e) {
        if (timesOfErr > 2) {
          await closeBrowser();
          Log.logger.e("browserClose".tr, error: e);
          final error = "网络错误 或 请求被拦截(请修改设置中的 Cloudflare Bypass Cookies): $e";
          dataFetchStatus.value = "-$error";
          UI.showNotification(error, type: NotificationType.error);
          return null;
        }
        timesOfErr++;
        await Future.delayed(Constants.universalDelay);
        continue;
      }
    }

    return jupiterPage;
  }

  static Future<bool> login(Page jupiterPage, {String? name, String? password}) async {
    // 填入学校信息
    try {
      await jupiterPage.type("#text_school1", "Georgia School Ningbo");
      await jupiterPage.type("#text_city1", "Ningbo");
      await jupiterPage.click("#showcity > div.menuspace");
      await Future.delayed(Constants.universalDelay);
      await jupiterPage.click("#menulist_region1 > div[val='xx_xx']");
    } catch (e) {
      await closeBrowser();
      Log.logger.e("browserClose".tr, error: e);
      final error = "登录 Jupiter 时发生未知异常: $e";
      dataFetchStatus.value = "-$error";
      UI.showNotification(error, type: NotificationType.error);
      return false;
    }

    // 进行登录
    if (name != null && password != null) {
      try {
        await jupiterPage.type("#text_studid1", name);
        await jupiterPage.type("#text_password1", password);
        await jupiterPage.click("#loginbtn");
      } catch (e) {
        await closeBrowser();
        Log.logger.e("browserClose".tr, error: e);
        final error = "登录 Jupiter 时发生未知异常: $e";
        dataFetchStatus.value = "-$error";
        UI.showNotification(error, type: NotificationType.error);
        return false;
      }
    } else {
      try {
        await jupiterPage.type("#text_studid1", SettingManager.settings["jupiterName"]!);
        await jupiterPage.type("#text_password1", SettingManager.settings["jupiterPassword"]!);
        await jupiterPage.click("#loginbtn");
      } catch (e) {
        await closeBrowser();
        Log.logger.e("browserClose".tr, error: e);
        final error = "登录 Jupiter 时发生未知异常: $e";
        dataFetchStatus.value = "-$error";
        UI.showNotification(error, type: NotificationType.error);
        return false;
      }
    }

    // 判断是否登录成功
    try {
      await jupiterPage.waitForSelector("div[class='toptabnull']", timeout: const Duration(seconds: 5));

      // 用于特殊调用，直接检查账号是否可用
      if (name != null && password != null) {
        await closeBrowser();
        Log.logger.i("browserClose".tr);
        return true;
      }
    } catch (_) {
      await closeBrowser();
      const error = "Jupiter 账号或密码错误";
      dataFetchStatus.value = "-$error";
      UI.showNotification(error, type: NotificationType.error);
      return false;
    }

    // 选择最新学年
    try {
      await jupiterPage.waitForSelector("div[class='hide null']");
      await jupiterPage.click("#schoolyeartab");
      await Future.delayed(Constants.universalDelay);
      await jupiterPage.click("#schoolyearlist > div:nth-child(1)");
    } catch (e) {
      await closeBrowser();
      Log.logger.e("browserClose".tr, error: e);
      const error = "学年列表出现异常，无法正常选择最新学年";
      dataFetchStatus.value = "-$error";
      UI.showNotification(error, type: NotificationType.error);
      return false;
    }

    return true;
  }

  static void checkForNewAssignment({int? retry}) async {
    // 如果传入的 retry 为 0 直接终止
    if (retry == 0) {
      await closeBrowser();
      Log.logger.i("browserClose".tr);
      return;
    }

    // 打开自动化浏览器并前往 Jupiter 登录页
    final jupiterPage = await openJupiterPage();
    if (jupiterPage == null) return;

    // 登录 Jupiter
    if (!(await login(jupiterPage))) return;

    // 获取科目数量
    late final int courseCount;
    try {
      courseCount = (await getCourses(jupiterPage)).length;
      await jupiterPage.click("#touchnavbtn");
    } catch (_) {
      await closeBrowser();
      return;
    }

    if (courseCount == 0) {
      await closeBrowser();
      lastUpdateTime.value = Utils.formatTime(DateTime.now());
      dataFetchStatus.value = "+";
      Log.logger.i("browserClose".tr);
      return;
    }

    //* --------------------------- 转跳到各个科目并记录作业列表数据 --------------------------- *//
    // 从数据库获取数据，或判空创建新的
    var jupiterData = await isar.jupiterDatas.filter().idEqualTo(0).findFirst();
    final List<Course> storedCourses = jupiterData!.courses!.toList();

    // 遍历查询课程列表中的作业数据
    var modification = 0;
    final modifiedCourses = [];
    final Map<int, List<Assignment>> assignmentsAwaitDesc = {};
    try {
      for (var i = 0; i < courseCount; i++) {
        final courses = await getCourses(jupiterPage);
        final courseName = await courses[i].evaluate("node => node.innerText");

        // 转跳到对应 Course 详情页
        courses[i].hover();
        await Future.delayed(Constants.universalDelay);
        jupiterPage.mouse.down();
        jupiterPage.mouse.up();
        await jupiterPage.waitForSelector("div[class='hide null']");
        await Future.delayed(Constants.universalDelay);

        // 检索当前科目的总成绩
        String? courseGrade;
        try {
          courseGrade = await jupiterPage.$eval(
            "#mainpage > div.printmargin > div.shrink > div:nth-child(4) > table > tbody > tr.baseline.botline.printblue",
            "el => el.cells[2].innerText + '  ' + el.cells[1].innerText",
          );
        } catch (_) {}

        // 检索 HTML 中的作业数据
        List assignments = await jupiterPage.$$eval(
          "table > tbody[click*='goassign'] > tr:nth-child(2)",
          """assignments => {
            const filterdList = [];
            assignments.map(item => {
              const due = item.cells[1].innerText;
              const title = item.cells[2].innerText;
              const score = item.cells[3].innerText;
              filterdList.push([due, title, score])
            })
            return filterdList;
        }""",
        );
        if (assignments.isEmpty) continue;

        // 通过 map 转换为作业对象数组
        assignments = assignments
            .map(
              (arr) => Assignment()
                ..due = _fromatJupiterDate(arr[0])
                ..title = arr[1]
                ..score = arr[2],
            )
            .toList();

        // 从科目列表中取出对应科目，判空创建新的
        Course? course = storedCourses.where((course) => course.name == courseName).firstOrNull;
        if (course == null) {
          storedCourses.add(
            Course()
              ..name = courseName
              ..assignments = assignments.cast()
              ..grade = courseGrade,
          );
          await NotificationQueue.push(
            Message()
              ..time = DateTime.now()
              ..title = "新作业提示"
              ..course = courseName
              ..assignments = assignments.cast(),
          );
          modifiedCourses.add(courseName);
          modification++;
          continue;
        }

        // 比较科目成绩，不同的话修改并需要写入
        if (course.grade != courseGrade) {
          course.grade = courseGrade;
          modification++;
        }

        // 比较数据库中的与新查询到的作业数据，差值，如无差值就跳过
        final modifications = await _findListDiff(assignments.cast(), course.assignments!);
        if (modifications["new"]!.isEmpty && modifications["score"]!.isEmpty) continue;

        // 如果有新作业
        if (modifications["new"]!.isNotEmpty) {
          await NotificationQueue.push(
            Message()
              ..time = DateTime.now()
              ..title = "新作业提示"
              ..course = courseName
              ..assignments = modifications["new"],
          );
          assignmentsAwaitDesc.addAll({i: modifications["new"]!});
        }

        // 如果有新成绩
        if (modifications["score"]!.isNotEmpty) {
          await NotificationQueue.push(
            Message()
              ..time = DateTime.now()
              ..title = "新成绩提示"
              ..course = courseName
              ..assignments = modifications["Δscore"],
          );
        }

        // 修改标识自增，将数据存入对象
        modification++;
        modifiedCourses.add(courseName);
        storedCourses.remove(course);
        storedCourses.add(course..assignments = assignments.cast());
        await Future.delayed(Constants.universalDelay);
      }
    } catch (e) {
      Log.logger.e("browserClose".tr, error: e);
      final error = "Chromium 自动化浏览器出现上下文异常，将进行重试: $e";
      dataFetchStatus.value = "-$error";
      UI.showNotification(error, type: NotificationType.error);
      await closeBrowser();
      checkForNewAssignment(retry: retry == null ? 3 : --retry);
      return;
    }

    // 如无修改就不再写入数据库，反之写入
    if (modification == 0) {
      await closeBrowser();
      lastUpdateTime.value = Utils.formatTime(DateTime.now());
      dataFetchStatus.value = "+";
      Log.logger.i("browserClose".tr);
      return;
    }

    jupiterData.courses = storedCourses;
    isar.writeTxn(() => isar.jupiterDatas.put(jupiterData));
    lastUpdateTime.value = Utils.formatTime(DateTime.now());
    localNotifier.notify(
      LocalNotification(
        title: modifiedCourses.isEmpty ? "$modification 门科目的整体成绩有变动" : "共有 ${modifiedCourses.length} 门科目有新作业 | 成绩",
        body: modifiedCourses.length > 4 ? modifiedCourses.join(", ") : modifiedCourses.join("\n"),
      ),
    );

    // 浏览器关闭前检测是否需要检索作业详情信息
    if (assignmentsAwaitDesc.isNotEmpty && assignmentsAwaitDesc.length < 12) {
      for (var entry in assignmentsAwaitDesc.entries) {
        final courses = await getCourses(jupiterPage);
        final courseName = await courses[entry.key].evaluate("node => node.innerText");

        try {
          courses[entry.key].hover();
          await Future.delayed(Constants.universalDelay);
          jupiterPage.mouse.down();
          jupiterPage.mouse.up();
          await jupiterPage.waitForSelector("div[class='hide null']");
          await Future.delayed(Constants.universalDelay);
        } catch (e) {
          Log.logger.e("browserClose".tr, error: e);
          final error = "Chromium 自动化浏览器出现上下文异常，作业详情信息获取失败: $e";
          dataFetchStatus.value = "-$error";
          UI.showNotification(error, type: NotificationType.error);
          await closeBrowser();
        }

        final course = jupiterData.courses!.firstWhere((course) => (course.name == courseName));
        await getAssignmentDesc(jupiterPage, course, entry.value);
      }

      // 再次写入数据库
      isar.writeTxn(() => isar.jupiterDatas.put(jupiterData));
    }

    await closeBrowser();
    dataFetchStatus.value = "+";
    Log.logger.i("browserClose".tr);
  }

  static Future<void> getAssignmentDesc(Page jupiterPage, Course course, List<Assignment> assignments) async {
    var timesOfErr = 0;

    for (var i = 0; i < assignments.length; i++) {
      try {
        final handles = await jupiterPage.$$("table > tbody[click*='goassign'] > tr:nth-child(2)");
        final List titles = await jupiterPage.$$eval(
          "table > tbody[click*='goassign'] > tr:nth-child(2)",
          """assignments => {
            const filterdList = [];
            assignments.map(item => {
              const title = item.cells[2].innerText;
              filterdList.push(title)
            })
            return filterdList;
        }""",
        );

        handles[titles.indexWhere((title) => title == assignments[i].title)].hover();
        await Future.delayed(Constants.universalDelay);
        jupiterPage.mouse.down();
        jupiterPage.mouse.up();
        await jupiterPage.waitForSelector("div[class='hide null']", timeout: const Duration(minutes: 1));
        await Future.delayed(Constants.universalDelay);
      } catch (e) {
        if (timesOfErr > 3) {
          await closeBrowser();
          Log.logger.e("browserClose".tr, error: e);
          final error = "Chromium 自动化浏览器出现多次上下文异常，作业详情信息获取失败: $e";
          dataFetchStatus.value = "-$error";
          UI.showNotification(error, type: NotificationType.error);
          timesOfErr = 0;
          continue;
        }
        timesOfErr++;
        i--;
      }

      late String desc;
      try {
        desc = await jupiterPage.$eval(
          "div[style='padding:0px 20px; max-width:472px;']",
          "node => node.innerText",
        );
      } catch (_) {
        desc = "None";
      }

      // 更新数据 + 返回 Assignments 页面
      course.assignments!.firstWhere((item) => item.title == assignments[i].title).desc = desc;
      jupiterPage.click("div[script*='grades']");
    }
  }

  static Future<List<ElementHandle>> getCourses(Page jupiterPage) async {
    await jupiterPage.waitForSelector("div[class='hide null']");
    await jupiterPage.click("#touchnavbtn");
    await Future.delayed(Constants.universalDelay);
    final courses = await jupiterPage.$$("#sidebar > div[click*='grades']");
    return courses;
  }

  static Future<Map<String, List<Assignment>>> _findListDiff(List<Assignment> l1, List<Assignment> l2) async {
    final Map<String, List<Assignment>> diff = {"new": [], "score": [], "Δscore": []};

    for (var item in l1) {
      final searchResult = l2.where(
        (assignment) => assignment.title == item.title && assignment.due == item.due,
      );
      if (searchResult.isEmpty) {
        diff["new"]!.add(item);
      } else if (searchResult.first.score != item.score) {
        diff["score"]!.add(item);
        diff["Δscore"]!.add(
          Assignment()
            ..due = _fromatJupiterDate(item.due!)
            ..title = item.title
            ..score = "${searchResult.first.score} → ${item.score}",
        );
      }
    }
    return diff;
  }

  static String _fromatJupiterDate(String raw) {
    if (raw.isEmpty) return "";
    if (raw.contains("-")) return raw;
    final parts = raw.split("/");
    if (parts[0].length < 2) parts[0] = "0${parts[0]}";
    if (parts[1].length < 2) parts[1] = "0${parts[1]}";
    return "${DateTime.now().year}-${parts[0]}-${parts[1]}";
  }
}
