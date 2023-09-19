import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:scannmay_toolkit/views/setting_view/setting_field.dart';
import 'package:scannmay_toolkit/functions/setting_manager/manager.dart';
import 'package:scannmay_toolkit/functions/setting_manager/jupiter_account_querier.dart';

class SettingView extends StatefulWidget {
  const SettingView({super.key});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  var settings = Map.from(SettingManager.settings);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Flex(
        direction: Axis.vertical,
        children: [
          const SizedBox(height: 24),
          SingleChildScrollView(
            child: Column(
              children: [
                SettingField(
                  property: "开机自启动",
                  desc: "在系统启动后自动打开应用并隐藏至托盘",
                  field: Switch(
                    value: bool.parse(settings["launchOnStartup"]!),
                    onChanged: (flag) {
                      setState(() => settings["launchOnStartup"] = flag.toString());
                      SettingManager.launchOnStartup(flag);
                    },
                  ),
                ),
                SettingField(
                  property: "数据检索间隔",
                  desc: "登录 Jupiter 并查看是否有新成绩或作业的时间间隔 (10 min ≤ t ≤ 120 min) *s",
                  field: Row(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 46,
                        child: TextField(
                          onChanged: (val) => settings["jupiterDataFetchInterval"] = val.isEmpty ? "10" : val,
                          controller: TextEditingController(
                            text: settings["jupiterDataFetchInterval"],
                          ),
                          decoration: const InputDecoration(hintText: "10"),
                          textAlign: TextAlign.center,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(3),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
                SettingField(
                  property: "Jupiter 账号",
                  desc: "用于登录 Jupiter ED 进行数据检索的学生账号",
                  field: ElevatedButton(
                    onPressed: () => JupiterAccountQuerier.updateAccount(),
                    child: const Text("更改账号"),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(child: SizedBox()),
          Flex(
            direction: Axis.horizontal,
            children: [
              Text(
                "*s = 该设置仅在点击保存后生效 | *r = 该设置仅在应用重启后生效",
                style: TextStyle(color: Colors.red.withAlpha(920)),
              ),
              const Expanded(child: SizedBox()),
              ElevatedButton(
                onPressed: () {
                  SettingManager.saveSettings(settings.cast());
                  setState(() => settings = Map.from(SettingManager.settings));
                },
                child: const Text("保存设置", style: TextStyle(color: Colors.green)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
