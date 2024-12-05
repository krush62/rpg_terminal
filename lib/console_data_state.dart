import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mcs/answers.dart';
import 'package:mcs/ship_status.dart';

enum ConsoleState
{
  none,
  start,
  output,
  input,
  shutdown,
  win,
  lose
}

enum CharacterColor
{
  normal,
  orange,
  red,
  yellow,
  blue,
  green,
  purple,
  gray
}

enum SoundType
{
  background,
  backspace,
  enter,
  input,
  output,
  shutdown,
  startup
}

class OutputElement
{
  final TextSpan textSpan;
  final bool singleCharacterMode;
  OutputElement({required this.textSpan, this.singleCharacterMode = true});
}

class ConsoleDataState with ChangeNotifier
{
  final ValueNotifier<ConsoleState> consoleStateNotifier = ValueNotifier(ConsoleState.none);

  ConsoleState get consoleState
  {
    return consoleStateNotifier.value;
  }
  final Queue<OutputElement> _outputBuffer = Queue();
  final Queue<TextSpan> _displayData = Queue();

  final int _maxInputLength = 32;

  bool firstRun = true;
  bool showsCursor = false;
  static final double fontSize = 16.0;
  static final TextStyle _defaultStyle = TextStyle(fontFamily: "ModernDos");
  static final Map<CharacterColor, TextStyle> _textStyleMap =
  {
    CharacterColor.normal: _defaultStyle.copyWith(color: Color.fromARGB(255, 150, 140, 130), fontSize: fontSize),
    CharacterColor.gray: _defaultStyle.copyWith(color: Color.fromARGB(255, 80, 70, 60), fontSize: fontSize),
    CharacterColor.orange: _defaultStyle.copyWith(color: Color.fromARGB(255, 160, 70, 20), fontSize: fontSize),
    CharacterColor.red: _defaultStyle.copyWith(color: Color.fromARGB(255, 200, 40, 40), fontSize: fontSize),
    CharacterColor.yellow: _defaultStyle.copyWith(color: Color.fromARGB(255, 130, 130, 40), fontSize: fontSize),
    CharacterColor.blue: _defaultStyle.copyWith(color: Color.fromARGB(255, 60, 70, 220), fontSize: fontSize),
    CharacterColor.green: _defaultStyle.copyWith(color: Color.fromARGB(255, 60, 120, 60), fontSize: fontSize),
    CharacterColor.purple: _defaultStyle.copyWith(color: Color.fromARGB(255, 100, 40, 100), fontSize: fontSize),
  };
  late TextSpan _currentInput = TextSpan(style: _textStyleMap[CharacterColor.normal], text: "");
  final String _allowedCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890 ";

  late TextSpan cursorSpan = TextSpan(text: "_", style: _textStyleMap[CharacterColor.normal]);
  late TextSpan prefix = TextSpan(text: "\n[USER_@_M0TH3R5H1P]: ", style: _textStyleMap[CharacterColor.orange]);

  bool _samplesCreated = false;
  //bool _levelLoaded = false;
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  final AudioPlayer _startUpMusicPlayer = AudioPlayer();
  final AudioPlayer _shutdownMusicPlayer = AudioPlayer();
  final AudioPlayer _outputMusicPlayer = AudioPlayer();

  final Map<SoundType, String> _soundPathMap =
  {
    SoundType.background: "sounds/Background.wav",
    SoundType.backspace: "sounds/Backspace.wav",
    SoundType.enter: "sounds/Enter.wav",
    SoundType.input: "sounds/Input.wav",
    SoundType.output: "sounds/Output.wav",
    SoundType.shutdown: "sounds/Shutdown.wav",
    SoundType.startup: "sounds/BootUp.wav",
  };

  late ShipStatus shipStatus;

  ConsoleDataState()
  {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _blinkTimeout(timer);
    },);

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      _writeOutputCharacter(timer);
    },);

    loadSamples();
    loadLevel();
  }


  static TextStyle getTextStyle(final CharacterColor color)
  {
    return _textStyleMap[color] ?? _defaultStyle.copyWith(color: Color.fromARGB(255, 160, 150, 140), fontSize: fontSize);
  }

  Future<void> loadSamples() async
  {
    await _bgMusicPlayer.setSource(AssetSource(_soundPathMap[SoundType.background] ?? ""));
    await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _startUpMusicPlayer.setSource(AssetSource(_soundPathMap[SoundType.startup] ?? ""));
    await _shutdownMusicPlayer.setSource(AssetSource(_soundPathMap[SoundType.shutdown] ?? ""));
    await _outputMusicPlayer.setSource(AssetSource(_soundPathMap[SoundType.output] ?? ""));
    await _outputMusicPlayer.setReleaseMode(ReleaseMode.stop);

    _samplesCreated = true;
  }

  Future<void> loadLevel() async
  {
    final String levelText = await rootBundle.loadString('assets/levels/layout1.txt');
    shipStatus = ShipStatus.fromLayoutData(levelText);

    //_levelLoaded = true;
  }

  void addOutputData({required final String text, required final CharacterColor color, final bool singleCharacterMode = true})
  {
    _outputBuffer.add(OutputElement(textSpan: TextSpan(text: text, style: getTextStyle(color)), singleCharacterMode: singleCharacterMode));
    if (consoleState == ConsoleState.input)
    {
      _switchState(ConsoleState.output);
    }
  }

  void addDisplayDataLine({required final List<TextSpan> spanList})
  {
    _displayData.addAll(spanList);
    _displayData.add(TextSpan(text: "\n", style: getTextStyle(CharacterColor.normal)));
    notifyListeners();
  }

  void powerPressed()
  {
    if (consoleState == ConsoleState.none)
    {
      _switchState(ConsoleState.start);
    }
    else if (consoleState == ConsoleState.input || consoleState == ConsoleState.output || consoleState == ConsoleState.win || consoleState == ConsoleState.lose)
    {
      _prepareShutdown();
    }
  }

  void _blinkTimeout(Timer t)
  {
    if (consoleState == ConsoleState.input)
    {
      showsCursor = !showsCursor;
      notifyListeners();
    }
  }

  List<TextSpan> getDisplayData()
  {
    final List<TextSpan> dData = _displayData.toList();
    if (consoleState == ConsoleState.input)
    {
      dData.add(_currentInput);
      if (showsCursor)
      {
        dData.add(cursorSpan);
      }
    }
    return dData;
  }

  void addInputCharacter(String character)
  {
    if (character.length == 1 && consoleState == ConsoleState.input && _allowedCharacters.contains(character) && _currentInput.text!.length <= _maxInputLength)
    {
      _currentInput = TextSpan(style: _currentInput.style, text: _currentInput.text! + character);
      notifyListeners();
      _playNewSound(SoundType.input);
    }
  }

  void confirmInputData()
  {
    if (consoleState == ConsoleState.input)
    {
      _playNewSound(SoundType.enter);
      _interpretInput();
      notifyListeners();
    }
  }

  void inputBackspace()
  {
    if (consoleState == ConsoleState.input && _currentInput.text!.isNotEmpty)
    {
      _currentInput = TextSpan(style: _currentInput.style, text: _currentInput.text!.substring(0, _currentInput.text!.length - 1));
      _playNewSound(SoundType.backspace);
      notifyListeners();
    }
  }

  void _interpretInput()
  {
    _displayData.add(_currentInput);
    notifyListeners();

    TerminalCommand? command = Answers.getCommand(_currentInput.text!);
    if (command != null && command.function != null)
    {
      command.function!(this, args: Answers.getArgs(_currentInput.text!));
    }
    else if (_currentInput.text != null && _currentInput.text!.isNotEmpty)
    {
      addOutputData(text: "\nUnknown command: ", color: CharacterColor.normal);
      addOutputData(text: _currentInput.text!, color: CharacterColor.purple);
    }
    if (_currentInput.text == "shutdown")
    {
      _prepareShutdown();
    }
    else if (consoleState != ConsoleState.win && consoleState != ConsoleState.lose && consoleState != ConsoleState.shutdown)
    {
      _switchState(ConsoleState.output);
    }

    _currentInput = TextSpan(style: _currentInput.style, text: "");
  }

  void _prepareShutdown()
  {
    _displayData.clear();
    _outputBuffer.clear();
    _switchState(ConsoleState.shutdown);
    notifyListeners();
  }

  void _writeOutputCharacter(Timer t)
  {
    if (consoleState == ConsoleState.output)
    {
      if (_outputBuffer.isNotEmpty)
      {
        final OutputElement first = _outputBuffer.removeFirst();
        if (first.textSpan.text != null && first.textSpan.text!.isNotEmpty)
        {
          if (first.singleCharacterMode)
          {
            final String char = first.textSpan.text![0];
            final TextSpan newFirst = TextSpan(text: first.textSpan.text!.substring(1), style: first.textSpan.style);
            _displayData.add(TextSpan(text: char, style: first.textSpan.style));
            _outputBuffer.addFirst(OutputElement(textSpan: newFirst, singleCharacterMode: first.singleCharacterMode));

          }
          else
          {
            final String line = first.textSpan.text!;
            _displayData.add(TextSpan(text: line, style: first.textSpan.style));
          }
          _outputMusicPlayer.resume();
          notifyListeners();
        }
      }
      else
      {
        //SWITCH TO INPUT WHEN OUTPUT IS COMPLETE
        _switchState(ConsoleState.input);
      }
    }
  }

  void _playNewSound(SoundType type)
  {
    final String? path = _soundPathMap[type];
    if (path != null && _samplesCreated)
    {
      AudioPlayer().play(AssetSource(path));
    }
  }

  void lose()
  {
    _switchState(ConsoleState.lose);
  }

  void win()
  {
    _switchState(ConsoleState.win);
  }

  void checkHealth()
  {
    if (shipStatus.character.hp <= 0)
    {
      _switchState(ConsoleState.lose);
    }
  }


  void _switchState(final ConsoleState targetState)
  {
    if (consoleState != ConsoleState.input && consoleState != ConsoleState.output && (targetState == ConsoleState.input || targetState == ConsoleState.output))
    {
      _bgMusicPlayer.resume();
    }
    else if (targetState != ConsoleState.input && targetState != ConsoleState.output && (consoleState == ConsoleState.input || consoleState == ConsoleState.output))
    {
      _bgMusicPlayer.stop();
    }

    if (targetState != consoleState)
    {
      switch(targetState)
      {
        case ConsoleState.none:
          break;
        case ConsoleState.start:
          loadLevel();
          _startUpMusicPlayer.onPlayerComplete.listen((event) {
            _switchState(ConsoleState.output);
          });
          _startUpMusicPlayer.resume();
          break;
        case ConsoleState.shutdown:
          _shutdownMusicPlayer.onPlayerComplete.listen((event) {
            _switchState(ConsoleState.none);
          });
          _shutdownMusicPlayer.resume();
          break;
        case ConsoleState.output:
          if (consoleState == ConsoleState.start)
          {
            Answers.addGreeting(this);
            Answers.mission(this);
          }
          break;
        case ConsoleState.input:
          _displayData.addLast(prefix);
          break;
        case ConsoleState.win:
          break;
        case ConsoleState.lose:
          break;
      }
      print("SWITCHING FROM $consoleState to $targetState");
      consoleStateNotifier.value = targetState;
      notifyListeners();
    }
  }


}