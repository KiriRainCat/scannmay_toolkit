import 'package:flutter/material.dart';
import 'package:scannmay_toolkit/components/rounded_button.dart';
import 'package:window_manager/window_manager.dart';

class WindowControls extends StatelessWidget {
  const WindowControls({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (details) => windowManager.startDragging(),
            ),
          ),
          RoundedButton(
            onPressed: () => windowManager.hide(),
            buttonContent: const Icon(Icons.close, size: 16, color: Colors.black),
            margin: const EdgeInsets.fromLTRB(0, 6, 8, 0),
            width: 18,
            height: 18,
          ),
        ],
      ),
    );
  }
}
