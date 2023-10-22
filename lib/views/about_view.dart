import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:scannmay_toolkit/functions/auto_updater/auto_updater.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key, required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "author".tr,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
        ),
        const SizedBox(height: 8),
        Text(
          "${"version".tr}: v$version",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: AutoUpdater.checkForUpdate,
          child: Text("checkUpdate".tr),
        ),
      ],
    );
  }
}
