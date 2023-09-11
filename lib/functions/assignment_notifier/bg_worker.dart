// cSpell: disable

import 'package:puppeteer/puppeteer.dart';
import 'package:scannmay_toolkit/constants.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';

class AssignmentNotifierBgWorker {
  static void checkForNewAssignment() async {
    // 创建浏览器对象，根据环境决定是否使用无头模式
    final browser = await puppeteer.launch(
      headless: Utils.ifProduction() ? true : false,
      defaultViewport: null,
    );
    final jupiterPage = await browser.newPage();

    // 前往 Jupiter 登录页
    await jupiterPage.goto("https://login.jupitered.com/login/", wait: Until.networkIdle);
    await Future.delayed(Constants.universalDelay);

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
    await jupiterPage.waitForSelector("#busy", visible: false);
    await jupiterPage.click("#schoolyeartab");
    await Future.delayed(Constants.universalDelay);
    await jupiterPage.click("#schoolyearlist > div:nth-child(1)");

    // 转跳到各个科目并记录作业列表数据
    final courseCount = (await _getCourses(jupiterPage)).length;
    await jupiterPage.click("#touchnavbtn");

    for (var i = 0; i < courseCount; i++) {
      final courses = await _getCourses(jupiterPage);
      final courseName = await courses[i].evaluate("node => node.innerText");

      // 转跳到对应 Course 详情页
      courses[i].hover();
      await Future.delayed(Constants.universalDelay);
      jupiterPage.mouse.down();
      jupiterPage.mouse.up();
      await jupiterPage.waitForSelector("#busy", visible: false);
      await Future.delayed(Constants.universalDelay);

      final length = await jupiterPage.$$eval(
        "table > tbody[click*='goassign'] > tr:nth-child(2)",
        "assignments => assignments.length",
      );
      print({courseName, length});
      await Future.delayed(Constants.universalDelay);
    }
  }

  static Future<List<ElementHandle>> _getCourses(Page jupiterPage) async {
    await jupiterPage.waitForSelector("#busy", visible: false);
    await jupiterPage.click("#touchnavbtn");
    await Future.delayed(Constants.universalDelay);
    final courses = await jupiterPage.$$("#sidebar > div[click*='grades']");
    if (courses.isEmpty) throw Exception("no course found");
    return courses;
  }
}
