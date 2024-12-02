
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
    TerminalCommand(command: "move", description: "Move the character to specified room/coordinate", function: move),
    TerminalCommand(command: "interact", description: "Lets the character interact with the current room."),
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

  static void move(final ConsoleDataState state, String args)
  {
    if (args.isNotEmpty)
    {
      final Room? r = state.shipStatus.getRoomByName(roomName: args);
      if (r != null)
      {
        final List<Room> allNeighborRooms = state.shipStatus.getNeighbouringRooms(false);
        final List<Room> openNeighborRooms = state.shipStatus.getNeighbouringRooms(true);
        if (allNeighborRooms.contains(r))
        {
          if (openNeighborRooms.contains(r))
          {
            state.addOutputData(text: "\nMoving to room ", color: CharacterColor.normal);
            state.addOutputData(text: "${r.name}\n", color: CharacterColor.purple);
            state.shipStatus.character.currentRoom = r;
            state.shipStatus.updateShipData();
          }
          else
          {
            state.addOutputData(text: "\nDoor to room ", color: CharacterColor.normal);
            state.addOutputData(text: r.name, color: CharacterColor.purple);
            state.addOutputData(text: " is locked!", color: CharacterColor.normal);
          }
        }
        else
        {
          state.addOutputData(text: "\nCannot reach ", color: CharacterColor.normal);
          state.addOutputData(text: "${r.name}\n", color: CharacterColor.purple);
        }
      }
      else
      {
        state.addOutputData(text: "\nCould not find room ", color: CharacterColor.normal);
        state.addOutputData(text: "$args\n", color: CharacterColor.purple);
      }
    }
    else
    {
      state.addOutputData(text: "\nPlease specify the room to move to!\n", color: CharacterColor.normal);
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