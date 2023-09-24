import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/main.dart';
import 'package:scannmay_toolkit/views/course_view/course_view.dart';
import 'package:scannmay_toolkit/views/home_view.dart';
import 'package:scannmay_toolkit/views/about_view.dart';
import 'package:scannmay_toolkit/views/notification_view/notification_view.dart';
import 'package:scannmay_toolkit/views/setting_view/setting_view.dart';

const textStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12.6);

///? 路由列表
final destinations = [
  const NavigationRailDestination(
    icon: Icon(Icons.home),
    label: Text("主页", style: textStyle),
  ),
  const NavigationRailDestination(
    icon: Icon(Icons.collections_bookmark),
    label: Text("科目", style: textStyle),
  ),
  const NavigationRailDestination(
    icon: Icon(Icons.notifications),
    label: Text("通知", style: textStyle),
  ),
  const NavigationRailDestination(
    icon: Icon(Icons.settings),
    label: Text("设置", style: textStyle),
  ),
  const NavigationRailDestination(
    icon: Icon(Icons.info),
    label: Text("关于", style: textStyle),
  ),
];

final destinationViews = [
  const HomeView(),
  const CourseView(),
  const NotificationView(),
  const SettingView(),
  AboutView(version: version)
];

///? 通过路由列表的 index 获取对应 View
Widget getCurrentView(int index) {
  try {
    return destinationViews[index];
  } catch (e) {
    throw UnimplementedError("no widget for selected index $index");
  }
}
