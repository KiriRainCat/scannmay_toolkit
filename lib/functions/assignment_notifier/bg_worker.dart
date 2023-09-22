// cSpell: disable

import 'dart:async';

import 'package:isar/isar.dart';
import 'package:puppeteer/puppeteer.dart';
import 'package:local_notifier/local_notifier.dart';

import 'package:scannmay_toolkit/constants.dart';
import 'package:scannmay_toolkit/model/jupiter.dart';
import 'package:scannmay_toolkit/model/notification.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/functions/setting_manager/manager.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/notification_queue.dart';

class AssignmentNotifierBgWorker {
  static late final Isar isar;

  static late Timer bgWorker;

  static late Browser browser;

  static void initAndStart(String dataFetchInterval, {Isar? db, bool? immediate}) {
    // 如果没有账号
    if (SettingManager.settings["jupiterName"] == null || SettingManager.settings["jupiterPassword"] == null) {}

    if (db != null) isar = db;
    if (immediate ??= false) checkForNewAssignment();
    bgWorker = Timer.periodic(Duration(minutes: int.parse(dataFetchInterval)), (_) => checkForNewAssignment());
  }

  static void forceStop() {
    try {
      AssignmentNotifierBgWorker.bgWorker.cancel();
      AssignmentNotifierBgWorker.browser.close();
    } catch (_) {}
  }

  static void clear() async {
    final jupiterData = await isar.jupiterDatas.filter().idEqualTo(0).findFirst();
    jupiterData!.courses = jupiterData.courses!.toList()..removeWhere((_) => true);
    isar.writeTxn(() => isar.jupiterDatas.put(jupiterData));
  }

  static Future<Page?> openJupiterPage() async {
    // 创建浏览器对象，根据环境决定是否使用无头模式
    late final Page jupiterPage;
    try {
      browser = await puppeteer.launch(
        headless: Utils.ifProduction() ? true : false,
        defaultViewport: null,
      );
      jupiterPage = await browser.newPage();
    } catch (e) {
      browser.close();
      UI.showNotification("Chromium 自动化浏览器启动异常: $e", type: NotificationType.error);
      return null;
    }

    // 前往 Jupiter 登录页
    try {
      await jupiterPage.goto("https://login.jupitered.com/login/", wait: Until.networkIdle);
      await jupiterPage.waitForSelector("#text_school1");
    } catch (e) {
      browser.close();
      UI.showNotification("网络错误，无法打开 Jupiter: $e", type: NotificationType.error);
      return null;
    }

    return jupiterPage;
  }

  static Future<bool> login(Page jupiterPage, {String? name, String? password}) async {
    // 填入学校信息
    await jupiterPage.type("#text_school1", "Georgia School Ningbo");
    await jupiterPage.type("#text_city1", "Ningbo");
    await jupiterPage.click("#showcity > div.menuspace");
    await Future.delayed(Constants.universalDelay);
    await jupiterPage.click("#menulist_region1 > div[val='xx_xx']");

    // 进行登录
    if (name != null && password != null) {
      await jupiterPage.type("#text_studid1", name);
      await jupiterPage.type("#text_password1", password);
      await jupiterPage.click("#loginbtn");
    } else {
      await jupiterPage.type("#text_studid1", SettingManager.settings["jupiterName"]!);
      await jupiterPage.type("#text_password1", SettingManager.settings["jupiterPassword"]!);
      await jupiterPage.click("#loginbtn");
    }

    // 判断是否登录成功
    try {
      await jupiterPage.waitForSelector("div[class='toptabnull']", timeout: const Duration(seconds: 5));

      // 用于特殊调用，直接检查账号是否可用
      if (name != null && password != null) {
        browser.close();
        return true;
      }
    } catch (_) {
      browser.close();
      UI.showNotification("Jupiter 账号或密码错误", type: NotificationType.error);
      return false;
    }

    // 选择最新学年
    try {
      await jupiterPage.waitForSelector("div[class='hide null']");
      await jupiterPage.click("#schoolyeartab");
      await Future.delayed(Constants.universalDelay);
      await jupiterPage.click("#schoolyearlist > div:nth-child(1)");
    } catch (e) {
      UI.showNotification("学年列表出现异常，无法正常选择最新学年", type: NotificationType.error);
      return false;
    }

    return true;
  }

  static void checkForNewAssignment({int? retry}) async {
    // 如果传入的 retry 为 0 直接终止
    if (retry == 0) return;

    // 打开自动化浏览器并前往 Jupiter 登录页
    final jupiterPage = await openJupiterPage();
    if (jupiterPage == null) return;

    // 登录 Jupiter
    if (!(await login(jupiterPage))) return;

    // 获取科目数量
    late final int courseCount;
    try {
      courseCount = (await _getCourses(jupiterPage)).length;
      await jupiterPage.click("#touchnavbtn");
    } catch (_) {
      browser.close();
      return;
    }

    if (courseCount == 0) {
      browser.close();
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
        final courses = await _getCourses(jupiterPage);
        final courseName = await courses[i].evaluate("node => node.innerText");

        // 转跳到对应 Course 详情页
        courses[i].hover();
        await Future.delayed(Constants.universalDelay);
        jupiterPage.mouse.down();
        jupiterPage.mouse.up();
        await jupiterPage.waitForSelector("div[class='hide null']");
        await Future.delayed(Constants.universalDelay);

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
                ..due = arr[0]
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
              ..assignments = assignments.cast(),
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
      UI.showNotification("Chromium 自动化浏览器出现上下文异常，将进行重试: $e", type: NotificationType.error);
      browser.close();
      checkForNewAssignment(retry: retry == null ? 2 : --retry);
      return;
    }

    // 如无修改就不再写入数据库，反之写入
    if (modification == 0) return;
    jupiterData.courses = storedCourses;
    isar.writeTxn(() => isar.jupiterDatas.put(jupiterData));
    localNotifier.notify(
      LocalNotification(
        title: "共有 ${modifiedCourses.length} 门科目有新作业 | 成绩",
        body: modifiedCourses.length > 4 ? modifiedCourses.join(", ") : modifiedCourses.join("\n"),
      ),
    );

    // 浏览器关闭前检测是否需要检索作业详情信息
    if (assignmentsAwaitDesc.isNotEmpty && assignmentsAwaitDesc.length < 20) {
      for (var entry in assignmentsAwaitDesc.entries) {
        final courses = await _getCourses(jupiterPage);
        final courseName = await courses[entry.key].evaluate("node => node.innerText");

        try {
          courses[entry.key].hover();
          await Future.delayed(Constants.universalDelay);
          jupiterPage.mouse.down();
          jupiterPage.mouse.up();
          await jupiterPage.waitForSelector("div[class='hide null']");
          await Future.delayed(Constants.universalDelay);
        } catch (e) {
          UI.showNotification("Chromium 自动化浏览器出现上下文异常，作业详情信息获取失败: $e", type: NotificationType.error);
          browser.close();
        }

        final course = jupiterData.courses!.firstWhere((course) => (course.name == courseName));
        await _getAssignmentDesc(jupiterPage, course, entry.value);
      }

      // 再次写入数据库
      isar.writeTxn(() => isar.jupiterDatas.put(jupiterData));
    }
    browser.close();
  }

  static Future<void> _getAssignmentDesc(Page jupiterPage, Course course, List<Assignment> assignments) async {
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
        await jupiterPage.waitForSelector("div[class='hide null']");
        await Future.delayed(Constants.universalDelay);
      } catch (e) {
        if (timesOfErr > 3) {
          UI.showNotification("Chromium 自动化浏览器出现多次上下文异常，作业详情信息获取失败: $e", type: NotificationType.error);
          browser.close();
          timesOfErr = 0;
          continue;
        }
        timesOfErr++;
        i--;
      }

      late final String desc;
      try {
        desc = await jupiterPage.$eval(
          "div[style='padding:0px 20px; max-width:472px;']",
          "node => node.innerText",
        );
      } catch (_) {
        jupiterPage.click("div[script*='grades']");
        continue;
      }

      // 更新数据 + 返回 Assignments 页面
      course.assignments!.firstWhere((item) => item.title == assignments[i].title).desc = desc;
      jupiterPage.click("div[script*='grades']");
    }
  }

  static Future<List<ElementHandle>> _getCourses(Page jupiterPage) async {
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
            ..due = item.due
            ..title = item.title
            ..score = "${searchResult.first.score} → ${item.score}",
        );
      }
    }
    return diff;
  }
}
