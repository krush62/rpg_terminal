
import 'package:flutter/material.dart';
import 'package:rpg_terminal/console_data_state.dart';
import 'package:rpg_terminal/ship_status.dart';



class TerminalCommand
{

  final String command;
  final String description;
  final Function(ConsoleDataState state, String args)? function;

  TerminalCommand({required this.command, required this.description, this.function});
}



class Answers
{

  static final List<TerminalCommand> commandList =
  [
    TerminalCommand(command: "help", description: "Show this help screen", function: addHelpMessage),
    TerminalCommand(command: "shutdown", description: "Shutdown of the system"),
    TerminalCommand(command: "map", description: "Show the map of the ship", function: showMap),
    TerminalCommand(command: "open", description: "Open specified air lock", function: openLock),
    TerminalCommand(command: "close", description: "Close specified air lock", function: closeLock),
  ];

  static void addHelpMessage(final ConsoleDataState state, String args)
  {
    int longestCommand = -1;
    for (final TerminalCommand command in commandList)
    {
      if (command.command.length > longestCommand)
      {
        longestCommand = command.command.length;
      }
    }

    state.addOutputData(text: "\nList of available commands:\n", color: CharacterColor.normal);
    for (final TerminalCommand command in commandList)
    {
      String spaces = "";
      for (int i = command.command.length; i <= longestCommand; i++)
      {
        spaces += " ";
      }
      state.addOutputData(text: "${command.command}$spaces", color: CharacterColor.purple);
      state.addOutputData(text: "${command.description}\n", color: CharacterColor.normal);
    }
  }

  static void showMap(final ConsoleDataState state, String args)
  {
    List<TextSpan> lineBreak = [
      TextSpan(text: "\n", style: ConsoleDataState.getTextStyle(CharacterColor.normal))
    ];
  state.addDisplayDataLine(spanList: lineBreak);

    final List<List<TextSpan>> shipData = state.shipStatus.getShipData();
    for (final List<TextSpan> dataLine in shipData)
    {
      state.addDisplayDataLine(spanList: dataLine);
    }
  }



  static void openLock(final ConsoleDataState state, String args)
  {
    AirLock? lock = state.shipStatus.getLockByName(args);
    if (lock == null)
    {
      state.addOutputData(text: "\nCould not find air lock with name ", color: CharacterColor.normal);
      state.addOutputData(text: args, color: CharacterColor.purple);
      state.addOutputData(text: ".", color: CharacterColor.normal);
    }
    else
    {
      if (lock.isOpen)
      {
        state.addOutputData(text: "\nAir lock ", color: CharacterColor.normal);
        state.addOutputData(text: lock.id, color: CharacterColor.purple);
        state.addOutputData(text: " is already open.", color: CharacterColor.normal);
      }
      else
      {
        state.addOutputData(text: "\nOpened air lock ", color: CharacterColor.normal);
        state.addOutputData(text: lock.id, color: CharacterColor.purple);
        state.addOutputData(text: ".", color: CharacterColor.normal);
        lock.isOpen = true;
        state.shipStatus.updateShipData();
      }
    }
  }

  static void closeLock(final ConsoleDataState state, String args)
  {
    AirLock? lock = state.shipStatus.getLockByName(args);
    if (lock == null)
    {
      state.addOutputData(text: "\nCould not find air lock with name ", color: CharacterColor.normal);
      state.addOutputData(text: args, color: CharacterColor.purple);
      state.addOutputData(text: ".", color: CharacterColor.normal);
    }
    else
    {
      if (!lock.isOpen)
      {
        state.addOutputData(text: "\nAir lock ", color: CharacterColor.normal);
        state.addOutputData(text: lock.id, color: CharacterColor.purple);
        state.addOutputData(text: " is already closed.", color: CharacterColor.normal);
      }
      else
      {
        state.addOutputData(text: "\nClosed air lock ", color: CharacterColor.normal);
        state.addOutputData(text: lock.id, color: CharacterColor.purple);
        state.addOutputData(text: ".", color: CharacterColor.normal);
        lock.isOpen = false;
        state.shipStatus.updateShipData();
      }
    }

  }

  static TerminalCommand? getCommand(String inputLine)
  {
    final List<String> split = inputLine.split(" ");
    final List<TerminalCommand> foundCommands = commandList.where((t) => t.command == split[0]).toList();
    if (foundCommands.isNotEmpty)
    {
      return foundCommands.first;
    }
    else
    {
      return null;
    }
  }

  static String getArgs(String inputLine)
  {
    final List<String> split = inputLine.split(" ");
    String result = "";
    if (split.length > 1)
    {
      for (int i = 1; i < split.length; i++)
      {
         result += split[i];
         if (i < split.length - 1)
         {
            result += " ";
         }
      }
    }
    return result;
  }

  static void addGreeting(final ConsoleDataState state)
  {
    addBigHeader(state);
    state.addOutputData(text: "\nWelcome to the Mothership Control System (MCS) v6.2\n", color: CharacterColor.green);
    state.addOutputData(text: "Enter your command. Type ", color: CharacterColor.normal);
    state.addOutputData(text: "help", color: CharacterColor.purple);
    state.addOutputData(text: " for a list of available commands.\n", color: CharacterColor.normal);
  }

  static void addBigHeader(final ConsoleDataState state)
  {
    state.addOutputData(text: "         ,8.       ,8.           ,o888888o.       d888888o.\n", color: CharacterColor.yellow, singleCharacterMode: false);
    state.addOutputData(text: "        ,888.     ,888.         8888     `88.   .`8888:' `88.\n", color: CharacterColor.yellow, singleCharacterMode: false);
    state.addOutputData(text: "       .`8888.   .`8888.     ,8 8888       `8.  8.`8888.   Y8\n", color: CharacterColor.yellow, singleCharacterMode: false);
    state.addOutputData(text: "      ,8.`8888. ,8.`8888.    88 8888            `8.`8888.\n", color: CharacterColor.orange, singleCharacterMode: false);
    state.addOutputData(text: "     ,8'8.`8888,8^8.`8888.   88 8888             `8.`8888.\n", color: CharacterColor.orange, singleCharacterMode: false);
    state.addOutputData(text: "    ,8' `8.`8888' `8.`8888.  88 8888              `8.`8888.\n", color: CharacterColor.orange, singleCharacterMode: false);
    state.addOutputData(text: "   ,8'   `8.`88'   `8.`8888. 88 8888               `8.`8888.\n", color: CharacterColor.orange, singleCharacterMode: false);
    state.addOutputData(text: "  ,8'     `8.`'     `8.`8888.`8 8888       .8' 8b   `8.`8888.\n", color: CharacterColor.red, singleCharacterMode: false);
    state.addOutputData(text: " ,8'       `8        `8.`8888.  8888     ,88'  `8b.  ;8.`8888\n", color: CharacterColor.red, singleCharacterMode: false);
    state.addOutputData(text: ",8'         `         `8.`8888.  `8888888P'     `Y8888P ,88P'\n", color: CharacterColor.red, singleCharacterMode: false);


  }
}