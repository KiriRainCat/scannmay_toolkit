import 'package:flutter/material.dart';

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
          "应用作者: 柒夜雨猫",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
        ),
        const SizedBox(height: 8),
        Text(
          "应用版本: v$version",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
        ),
        const SizedBox(height: 4),
        const TextButton(
          onPressed: AutoUpdater.checkForUpdate,
          child: Text("检查更新"),
        ),
      ],
    );
  }
}
