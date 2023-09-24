import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final double width;
  final double height;
  final void Function() onPressed;
  final Widget buttonContent;
  final EdgeInsetsGeometry? margin;
  final Color? bgColor;
  final String? tooltip;

  const RoundedButton({
    super.key,
    required this.width,
    required this.height,
    required this.onPressed,
    required this.buttonContent,
    this.margin,
    this.bgColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
      ),
      child: tooltip == null
          ? InkWell(
              onTap: onPressed,
              child: buttonContent,
            )
          : Tooltip(
              message: tooltip,
              child: InkWell(
                onTap: onPressed,
                child: buttonContent,
              ),
            ),
    );
  }
}
