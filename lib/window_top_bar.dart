import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class TheTopBar extends StatelessWidget {
  final Color color;
  const TheTopBar({super.key, required this.color});
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: WindowTitleBarBox(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: MoveWindow()), const WindowButtons()],
        ),
      ),
    );
  }
}

final buttonColors = WindowButtonColors(
    iconNormal: const Color(0xFF555555),
    mouseOver: const Color(0xFF888888),
    mouseDown: const Color(0xFFAAAAAA),
    iconMouseOver: const Color(0xFF000000),
    iconMouseDown: const Color(0xFF000000));

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        //MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: buttonColors),
      ],
    );
  }
}
