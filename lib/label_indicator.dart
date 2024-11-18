import 'package:flutter/material.dart';
import 'package:rpg_terminal/console_data_state.dart';

class LabelIndicator extends StatefulWidget {
  final ValueNotifier<ConsoleState> consoleStateNotifier;
  final TextStyle textStyle;
  final double fontSize;
  final String text;
  const LabelIndicator({super.key, required this.consoleStateNotifier, required this.textStyle, required this.fontSize, required this.text});

  @override
  State<LabelIndicator> createState() => _LabelIndicatorState();
}

class _LabelIndicatorState extends State<LabelIndicator>
{
  final Color _labelBlurColorRed = Color.fromARGB(255, 220, 100, 20);
  final Color _labelBlurColorBlue = Color.fromARGB(255, 100, 80, 255);
  final Color _labelBlurColorGreen = Color.fromARGB(255, 40, 160, 0);
  final Color _labelBlurColorNone = Color.fromARGB(0, 0, 0, 0);

  @override
  Widget build(BuildContext context)
  {
    return ValueListenableBuilder<ConsoleState>(
      valueListenable:  widget.consoleStateNotifier,
      builder: (final BuildContext context, final ConsoleState consoleState, final Widget? child) {
        Color blurColor = _labelBlurColorBlue;
        if (consoleState == ConsoleState.input) blurColor = _labelBlurColorGreen;
        if (consoleState == ConsoleState.output) blurColor = _labelBlurColorRed;
        if (consoleState == ConsoleState.none) blurColor = _labelBlurColorNone;
        return Text(
            widget.text,
            style: widget.textStyle.copyWith(
            color: Colors.black.withAlpha(150),
            fontSize: widget.fontSize,
            decoration: TextDecoration.none,

            shadows: <Shadow>[
              BoxShadow(
                  color: blurColor,
                  spreadRadius: 50.0,
                  blurRadius: 50.0,
                  blurStyle: BlurStyle.outer
              ),
              BoxShadow(
                  color: blurColor.withAlpha(200),
                  spreadRadius: 50.0,
                  blurRadius: 10.0,
                  blurStyle: BlurStyle.inner
              ),
              Shadow(
                  color: Colors.white.withAlpha(50),
                  blurRadius: 1.0,
                  offset: Offset(0.0, -2)
              ),
              Shadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 1.0,
                  offset: Offset(0.0, 2)
              )
            ]
          )
        );
      },
    );
  }
}
