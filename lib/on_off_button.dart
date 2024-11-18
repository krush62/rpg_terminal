import 'package:flutter/material.dart';
import 'package:rpg_terminal/console_data_state.dart';

class OnOffButton extends StatefulWidget {
  const OnOffButton({super.key, required this.consoleStateNotifier, required this.pressCallback, required this.buttonWidth, required this.buttonHeight});
  final double buttonWidth;
  final double buttonHeight;
  final ValueNotifier<ConsoleState> consoleStateNotifier;
  final Function() pressCallback;
  @override
  State<OnOffButton> createState() => _OnOffButtonState();
}

class _OnOffButtonState extends State<OnOffButton> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.consoleStateNotifier,
      builder: (final BuildContext context, final ConsoleState consoleState, final Widget? child) {
        Color blurColor = Colors.red.withAlpha(200);
        Color backgroundColor = Colors.red.withAlpha(100);
        Color overlayColor = Colors.red.withAlpha(120);
        if (consoleState == ConsoleState.none)
        {
          blurColor = Colors.red.withAlpha(0);
          backgroundColor = Colors.red.withAlpha(0);
          overlayColor = Colors.red.withAlpha(20);
        }

        return Container(
          width: widget.buttonWidth,
          height: widget.buttonHeight,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(12.0),
              ),
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: blurColor,
                  spreadRadius: 2,
                  blurRadius: 24,
                  offset: Offset(0, 0),
                ),
              ]
          ),
          child: IconButton.outlined(
            icon: Icon(Icons.power_settings_new, color: Colors.white.withAlpha(120),),
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(backgroundColor),
                elevation: WidgetStateProperty.resolveWith<double>((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return 0.0;
                  } else {
                    return 12.0;
                  }
                }),
                shadowColor: WidgetStateProperty.all<Color>(Colors.black),
                overlayColor: WidgetStateProperty.all<Color>(overlayColor),
                shape: WidgetStateProperty.resolveWith<OutlinedBorder?>((states) {
                  // Rounded button (when the button is pressed)
                  if (states.contains(WidgetState.pressed)) {
                    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));
                  } else {
                    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
                  }

                }),
                side: WidgetStateProperty.all<BorderSide>(BorderSide(
                    color: Colors.white.withAlpha(550),
                    width: 2.0,
                    style: BorderStyle.solid))


            ),
            onPressed: widget.pressCallback,
          ),
        );
      },
    );
  }
}
