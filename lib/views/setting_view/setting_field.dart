import 'package:flutter/material.dart';

class SettingField extends StatelessWidget {
  const SettingField({
    super.key,
    required this.property,
    required this.desc,
    required this.field,
  });

  final String property;
  final String desc;

  final Widget field;

  @override
  Widget build(BuildContext context) {
    TextStyle primaryTextStyle = const TextStyle(fontWeight: FontWeight.bold, fontSize: 18);
    TextStyle secondaryTextStyle = const TextStyle(color: Colors.black54, fontSize: 14);

    return Column(
      children: [
        Flex(
          direction: Axis.horizontal,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property, style: primaryTextStyle),
                Text(desc, style: secondaryTextStyle)
              ],
            ),
            const Expanded(child: SizedBox()),
            field,
          ],
        ),
        const SizedBox(height: 10),
        const Divider(height: 10),
        const SizedBox(height: 10),
      ],
    );
  }
}
