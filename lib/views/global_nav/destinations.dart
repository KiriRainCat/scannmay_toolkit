import 'package:flutter/material.dart';

import 'package:scannmay_toolkit/main.dart';
import 'package:scannmay_toolkit/views/home_view.dart';
import 'package:scannmay_toolkit/views/about_view.dart';

const textStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12.6);

///? 路由列表
final destinations = [
  const NavigationRailDestination(
    icon: Icon(Icons.home),
    label: Text("主页", style: textStyle),
  ),
  const NavigationRailDestination(
    icon: Icon(Icons.info),
    label: Text("关于", style: textStyle),
  ),
];

final destinationViews = [const HomeView(), AboutView(version: version)];

///? 通过路由列表的 index 获取对应 View
Widget getCurrentView(int index) {
  try {
    return destinationViews[index];
  } catch (e) {
    throw UnimplementedError("no widget for selected index $index");
  }
}
