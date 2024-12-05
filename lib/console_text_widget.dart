import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mcs/console_data_state.dart';

class ConsoleTextWidget extends StatefulWidget {
  const ConsoleTextWidget({super.key, required this.consoleDataState});
  final ConsoleDataState consoleDataState;

  @override
  State<ConsoleTextWidget> createState() => _ConsoleTextWidgetState();
}

class _ConsoleTextWidgetState extends State<ConsoleTextWidget>
{

  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.consoleDataState,
      builder: (final BuildContext context, final Widget? child) {

        if (_scrollController.positions.isNotEmpty && _scrollController.position.extentTotal != _scrollController.position.maxScrollExtent)
        {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }

        return KeyboardListener(
          autofocus: true,
          focusNode: _focusNode,
          onKeyEvent: (final KeyEvent keyEvent) {
            if (keyEvent.runtimeType != KeyUpEvent)
            {
              if (keyEvent.character != null)
              {
                widget.consoleDataState.addInputCharacter(keyEvent.character!);
              }
              else
              {
                if (keyEvent.logicalKey == LogicalKeyboardKey.enter)
                {
                  widget.consoleDataState.confirmInputData();
                }
                else if (keyEvent.logicalKey == LogicalKeyboardKey.backspace)
                {
                  widget.consoleDataState.inputBackspace();
                }
              }
            }
          },
          child: Builder(
            builder: (final BuildContext context)
            {
              if (widget.consoleDataState.consoleState == ConsoleState.start)
              {
                return Image.asset("assets/images/Startup.png", fit: BoxFit.contain);
              }
              else if (widget.consoleDataState.consoleState == ConsoleState.shutdown)
              {
                return Image.asset("assets/images/Shutdown.png", fit: BoxFit.contain);
              }
              else if (widget.consoleDataState.consoleState == ConsoleState.win)
              {
                return Image.asset("assets/images/Winning.png", fit: BoxFit.contain);
              }
              else if (widget.consoleDataState.consoleState == ConsoleState.lose)
              {
                return Image.asset("assets/images/Losing.png", fit: BoxFit.contain);
              }
              else
              {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SingleChildScrollView(
                    physics: NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    controller: _scrollController,
                    child: RichText(
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.start,
                      text: TextSpan(
                          children: widget.consoleDataState.getDisplayData()
                      )
                    ),
                  ),
                );
              }
            },
          )
        );
      },
    );
  }
}
