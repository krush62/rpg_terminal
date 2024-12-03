import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:ui' as ui;
import 'package:flutter_shaders/flutter_shaders.dart';
import 'package:rpg_terminal/console_data_state.dart';
import 'package:rpg_terminal/console_text_widget.dart';
import 'package:rpg_terminal/label_indicator.dart';
import 'package:rpg_terminal/on_off_button.dart';
import 'package:rpg_terminal/window_top_bar.dart';

const double windowWidth = 900;
const double windowHeight = 800;

void main() {
  runApp(const RPGTerminalApp());
  doWhenWindowReady(() {
    const initialSize = Size(windowWidth, windowHeight);
    appWindow.minSize = initialSize;
    appWindow.maxSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

const Color windowBorderColor = Colors.black;
const Color windowBackgroundColor = Color.fromARGB(255, 35, 30, 25);
const double consolePadding = 48;
const double paddingBottom = 128;
const double windowBorderWidth = 2;

class RPGTerminalApp extends StatelessWidget {
  const RPGTerminalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RPG Terminal',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: WindowBorder(
        color: windowBorderColor,
        width: windowBorderWidth,
        child: ColoredBox(
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: consolePadding, width: windowWidth, child: TheTopBar(color: windowBackgroundColor)),
              //if (kIsWeb) Container(width: windowWidth, height: consolePadding, color: windowBackgroundColor),
              SizedBox(width: windowWidth, height: windowHeight - consolePadding - (2 * windowBorderWidth), child: const RPGTerminal(title: 'RPG Terminal')),
            ],
          ),
        ),//,
        ),
    );
  }
}

class RPGTerminal extends StatefulWidget {
  const RPGTerminal({super.key, required this.title});
  final String title;

  @override
  State<RPGTerminal> createState() => _RPGTerminalState();
}

class _RPGTerminalState extends State<RPGTerminal> with SingleTickerProviderStateMixin
{
  static const double _borderRadius = 16;
  static const Color _terminalBgColor = Color.fromARGB(255, 5, 2, 0);
  late ConsoleDataState _consoleDataState;

  late final Ticker _ticker;
  double _elapsedTime = 0.0;

  @override
  void initState()
  {
    super.initState();
    _consoleDataState = ConsoleDataState(context);
    _ticker = Ticker((elapsed) {
      setState(() {
        _elapsedTime = elapsed.inMilliseconds / 1000;
      });
    });
    _ticker.start();

  }

  @override
  Widget build(BuildContext context)
  {
    return Container(

      color: windowBackgroundColor,
      child: Padding(
        padding: EdgeInsets.only(left: consolePadding, right: consolePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Divider(height: 2, thickness: 2, color: Colors.black.withAlpha(40), indent: _borderRadius, endIndent: _borderRadius,),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(_borderRadius)),
                child: ValueListenableBuilder<ConsoleState>(
                  valueListenable: _consoleDataState.consoleStateNotifier,
                  builder: (final BuildContext context, final ConsoleState consoleState, final Widget? child) {
                    if (consoleState == ConsoleState.none)
                    {
                      return Container(
                          decoration: const BoxDecoration(
                          gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                          Color(0xff252222),
                          Color(0xff151111),
                          Color(0xff050000),
                          ],
                          tileMode: TileMode.clamp,
                          ),
                          ));
                    }
                    else
                    {
                      return ShaderBuilder(
                        assetKey: 'shaders/crt.frag',
                            (BuildContext context, FragmentShader shader, _) => AnimatedSampler(
                                (final ui.Image image, final Size size, final Canvas canvas) {
                              shader
                                ..setFloat(0, _elapsedTime)
                                ..setFloat(1, size.width)
                                ..setFloat(2, size.height)
                                ..setFloat(3, 0.2) //vertical jumping
                                ..setFloat(4, 0.1) //vertical roll
                                ..setFloat(5, 0.3) //static
                                ..setFloat(6, 1.0) //scan lines
                                ..setFloat(7, 0.3) //rgb
                                ..setFloat(8, 0.25) //horizontal fuzz
                                ..setFloat(9, 12) //blur/glow
                                ..setImageSampler(0, image);
                              canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
                            },
                            child: ColoredBox(
                              color: _terminalBgColor,
                              child: ConsoleTextWidget(consoleDataState: _consoleDataState),
                            )
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            Divider(height: 2, thickness: 2, color: Colors.white.withAlpha(20), indent: _borderRadius, endIndent: _borderRadius,),
            SizedBox(
              height: 128,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        OnOffButton(
                          consoleStateNotifier: _consoleDataState.consoleStateNotifier,
                          pressCallback: _consoleDataState.powerPressed,
                          buttonWidth: 48,
                          buttonHeight: 48
                        ),
                        Expanded(
                            child: SizedBox.shrink()
                        ),
                      ],
                    ),
                  ),
                  Center(
                    child: LabelIndicator(
                        consoleStateNotifier: _consoleDataState.consoleStateNotifier,
                        textStyle: TextStyle(fontFamily: 'Argon', fontWeight: FontWeight.w500),
                        fontSize: 72,
                        text: "mothership",
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: ColoredBox(color: Colors.transparent)
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

