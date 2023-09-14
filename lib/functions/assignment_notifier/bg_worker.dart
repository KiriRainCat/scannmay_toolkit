// cSpell: disable

import 'dart:async';

import 'package:isar/isar.dart';
import 'package:puppeteer/puppeteer.dart';

import 'package:scannmay_toolkit/constants.dart';
import 'package:scannmay_toolkit/model/jupiter.dart';
import 'package:scannmay_toolkit/model/notification.dart';
import 'package:scannmay_toolkit/functions/utils/ui.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';
import 'package:scannmay_toolkit/functions/assignment_notifier/notification_queue.dart';

class AssignmentNotifierBgWorker {
  static late final Isar isar;

  static late final Timer bgWorker;

  static void initAndStart(Isar db) {
    isar = db;
  }

  static void checkForNewAssignment() async {
    // 创建浏览器对象，根据环境决定是否使用无头模式
    final browser = await puppeteer.launch(
      headless: Utils.ifProduction() ? true : false,
      defaultViewport: null,
    );
    final jupiterPage = await browser.newPage();

    // 前往 Jupiter 登录页
    await jupiterPage.goto("https://login.jupitered.com/login/", wait: Until.networkIdle);
    await jupiterPage.waitForSelector("#text_school1");

    // 填入学校信息
    await jupiterPage.type("#text_school1", "Georgia School Ningbo");
    await jupiterPage.type("#text_city1", "Ningbo");
    await jupiterPage.click("#showcity > div.menuspace");
    await Future.delayed(Constants.universalDelay);
    await jupiterPage.click("#menulist_region1 > div[val='xx_xx']");

    // 进行登录
    await jupiterPage.type("#text_studid1", "1271");
    await jupiterPage.type("#text_password1", "zjq1234567");
    await jupiterPage.click("#loginbtn");

    // 选择最新学年
    await jupiterPage.waitForSelector("div[class='hide null']");
    await jupiterPage.click("#schoolyeartab");
    await Future.delayed(Constants.universalDelay);
    await jupiterPage.click("#schoolyearlist > div:nth-child(1)");

    // 获取科目数量
    final courseCount = (await _getCourses(jupiterPage)).length;
    await jupiterPage.click("#touchnavbtn");
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
        var msg = "";
        for (var assignment in assignments) {
          msg += "${assignment.due} ${assignment.title}\n";
        }
        UI.showNotification("新作业: \n$msg");
        modification++;
        continue;
      }

      // 比较数据库中的与新查询到的作业数据，差值，如无差值就跳过
      final modifications = await _findListDiff(assignments.cast(), course.assignments!);
      if (modifications["new"]!.isEmpty && modifications["score"]!.isEmpty) continue;

      // 如果有新作业
      if (modifications["new"]!.isNotEmpty) {
        NotificationQueue.push(
          Message()
            ..time = DateTime.now()
            ..title = "新作业提示"
            ..course = courseName
            ..assignments = modifications["new"],
        );
      }

      // 如果有新成绩
      if (modifications["score"]!.isNotEmpty) {
        NotificationQueue.push(
          Message()
            ..time = DateTime.now()
            ..title = "新成绩提示"
            ..course = courseName
            ..assignments = modifications["score"],
        );
      }

      // 修改标识自增，将数据存入对象
      modification++;
      storedCourses.remove(course);
      storedCourses.add(course..assignments = assignments.cast());
      await Future.delayed(Constants.universalDelay);
    }

    // 如无修改就不再写入数据库，反之写入
    browser.close();
    if (modification == 0) return;
    jupiterData.courses = storedCourses;
    isar.writeTxn(() => isar.jupiterDatas.put(jupiterData));
  }

  static Future<List<ElementHandle>> _getCourses(Page jupiterPage) async {
    await jupiterPage.waitForSelector("div[class='hide null']");
    await jupiterPage.click("#touchnavbtn");
    await Future.delayed(Constants.universalDelay);
    final courses = await jupiterPage.$$("#sidebar > div[click*='grades']");
    return courses;
  }

  static Future<Map<String, List<Assignment>>> _findListDiff(
      List<Assignment> l1, List<Assignment> l2) async {
    final Map<String, List<Assignment>> diff = {"new": [], "score": []};

    for (var item in l1) {
      final searchResult = l2.where(
        (assignment) => assignment.title == item.title && assignment.due == item.due,
      );
      if (searchResult.isEmpty) {
        diff["new"]!.add(item);
      } else if (searchResult.first.score != item.score) {
        diff["score"]!.add(item..score = "${searchResult.first.score} → ${item.score}");
      }
    }
    return diff;
  }
}
