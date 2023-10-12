import 'package:flutter/material.dart';
import 'package:scannmay_toolkit/components/jupiter_data_status_bar.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  var selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: const Column(
        children: [
          JupiterDataStatusBar(),
          SizedBox(height: 24),
          Text("作业日程表页面仍在开发中，敬请期待~ (开发者爆肝 ing)"),
        ],
      ),
    );
  }
}
