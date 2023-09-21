import 'package:flutter/material.dart';
import 'package:scannmay_toolkit/components/rounded_button.dart';
import 'package:scannmay_toolkit/functions/utils/utils.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoundedButton(
              width: 64,
              height: 64,
              onPressed: () => Utils.openUrl("https://login.jupitered.com/login/"),
              buttonContent: Card(child: Image.asset("assets/images/icon_jupiter.png")),
            ),
            const SizedBox(width: 8),
            RoundedButton(
              width: 64,
              height: 64,
              onPressed: () => Utils.openUrl("https://outlook.office.com/mail/"),
              buttonContent: Card(
                child: Image.asset("assets/images/icon_outlook.png"),
              ),
            ),
            const SizedBox(width: 8),
            RoundedButton(
              width: 64,
              height: 64,
              onPressed: () => Utils.openUrl("https://teams.microsoft.com/"),
              buttonContent: Card(child: Image.asset("assets/images/icon_teams.png")),
            ),
          ],
        ),
      ],
    );
  }
}
