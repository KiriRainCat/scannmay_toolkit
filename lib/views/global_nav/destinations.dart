import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:scannmay_toolkit/main.dart';
import 'package:scannmay_toolkit/views/course_view/course_view.dart';
import 'package:scannmay_toolkit/views/home_view.dart';
import 'package:scannmay_toolkit/views/about_view.dart';
import 'package:scannmay_toolkit/views/notification_view/notification_view.dart';
import 'package:scannmay_toolkit/views/schedule_view/schedule_view.dart';
import 'package:scannmay_toolkit/views/setting_view/setting_view.dart';

const textStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12.6);

///? 路由列表
final destinations = [
  NavigationRailDestination(
    icon: const Icon(Icons.home),
    label: Text("homePage".tr, style: textStyle),
  ),
  NavigationRailDestination(
    icon: const Icon(Icons.collections_bookmark),
    label: Text("class".tr, style: textStyle),
  ),
  NavigationRailDestination(
    icon: const Icon(Icons.notifications),
    label: Text("notification".tr, style: textStyle),
  ),
  NavigationRailDestination(
    icon: const Icon(Icons.date_range),
    label: Text("calender".tr, style: textStyle),
  ),
  NavigationRailDestination(
    icon: const Icon(Icons.settings),
    label: Text("setting".tr, style: textStyle),
  ),
  NavigationRailDestination(
    icon: const Icon(Icons.info),
    label: Text("about".tr, style: textStyle),
  ),
];

final destinationViews = [
  const HomeView(),
  const CourseView(),
  const NotificationView(),
  const ScheduleView(),
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
