import 'package:get/get.dart';
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
                // TODO: 修复并兼容开机自启至多系统
                // SettingField(
                //   property: "${"autoBoot".tr}",
                //   desc: "desc2".tr,
                //   field: Switch(
                //     value: bool.parse(settings["launchOnStartup"]!),
                //     onChanged: (flag) {
                //       setState(() => settings["launchOnStartup"] = flag.toString());
                //       SettingManager.launchOnStartup(flag);
                //     },
                //   ),
                // ),
                SettingField(
                  property: "language".tr,
                  desc: "desc1".tr,
                  field: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: DropdownButtonFormField(
                          value: Get.locale,
                          items: const [
                            DropdownMenuItem(value: Locale("zh", "CN"), child: Text("简体中文")),
                            DropdownMenuItem(value: Locale("en", "US"), child: Text("English")),
                            DropdownMenuItem(value: Locale("ko", "KR"), child: Text("한국어")),
                          ],
                          onChanged: (value) => SettingManager.locale(value!),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ),
                ),
                SettingField(
                  property: "dataFetchInterval".tr,
                  desc: "desc3".tr,
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
                  property: "jupiterAccountInfo".tr,
                  desc: "desc4".tr,
                  field: ElevatedButton(
                    onPressed: () => JupiterAccountQuerier.updateAccount(),
                    child: Text("changeAccount".tr),
                  ),
                ),
                SettingField(
                  property: "Cloudflare Bypass Cookies",
                  desc: "desc5".tr,
                  field: ElevatedButton(
                    onPressed: () => SettingManager.cfCookieStr(),
                    child: Text("change".tr),
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
                "info6".tr,
                style: TextStyle(color: Colors.red.withAlpha(920)),
              ),
              const Expanded(child: SizedBox()),
              ElevatedButton(
                onPressed: () {
                  SettingManager.saveSettings(settings.cast());
                  setState(() => settings = Map.from(SettingManager.settings));
                },
                child: Text("saveSettings".tr, style: const TextStyle(color: Colors.green)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
