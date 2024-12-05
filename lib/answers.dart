
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mcs/console_data_state.dart';
import 'package:mcs/ship_status.dart';



class TerminalCommand
{

  final String command;
  final String description;
  final Function(ConsoleDataState state, {required String args})? function;

  TerminalCommand({required this.command, required this.description, this.function});
}



class Answers
{

  static final List<TerminalCommand> commandList =
  [
    TerminalCommand(command: "help", description: "Show this help screen (0 AP)", function: addHelpMessage),
    TerminalCommand(command: "shutdown", description: "Shutdown of the system"),
    TerminalCommand(command: "status", description: "Show the map and character status (0 AP)", function: showStatus),
    TerminalCommand(command: "move", description: "Move the character to specified room/coordinate (1 AP)", function: move),
    TerminalCommand(command: "interact", description: "Lets the character interact with the current room. (2 AP)", function: interact),
    TerminalCommand(command: "take", description: "Lets the character pick up the mission item. (2 AP)", function: take),
    TerminalCommand(command: "info", description: "Displays information about the current room. (0 AP)", function: info),
    TerminalCommand(command: "mission", description: "Displays information about your mission. (0 AP)", function: mission),
  ];

  static void addHelpMessage(final ConsoleDataState state, {String args = ""})
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

  static void info(final ConsoleDataState state, {String args = ""})
  {
    state.addOutputData(text: "\n${state.shipStatus.character.currentRoom.name}: ", color: CharacterColor.purple);
    state.addOutputData(text: roomInfoMap[state.shipStatus.character.currentRoom.roomType]?? "<NO DATA>", color: CharacterColor.normal);
  }

  static void mission(final ConsoleDataState state, {String args = ""})
  {
    state.addOutputData(text: "\nYOUR MISSION: ", color: CharacterColor.red);
    state.addOutputData(text: "Get the item from room ", color: CharacterColor.normal);
    state.addOutputData(text: state.shipStatus.targetRoom.name, color: CharacterColor.purple);
    state.addOutputData(text: " and return to the escape pod.", color: CharacterColor.normal);
  }

  static void take(final ConsoleDataState state, {String args = ""})
  {
    final charRoom = state.shipStatus.character.currentRoom;
    if (state.shipStatus.character.hasItem)
    {
      state.addOutputData(text: "\nMission item already acquired.", color: CharacterColor.red);
    }
    else
    {
      if (charRoom == state.shipStatus.targetRoom)
      {
        state.addOutputData(text: "\nTook mission item.", color: CharacterColor.green);
        state.shipStatus.character.hasItem = true;
        state.shipStatus.updateShipData(2);
        showStatus(state);
        state.checkHealth();
      }
      else
      {
        state.addOutputData(text: "\nMission item is not in this room!", color: CharacterColor.red);
      }
    }
  }

  static void interact(final ConsoleDataState state, {String args = ""})
  {
    final charRoom = state.shipStatus.character.currentRoom;
    if (charRoom.hasInteraction)
    {
      bool interacted = true;
      switch (charRoom.roomType)
      {
        case RoomType.noRoom:
          interacted = false;
          break;
        case RoomType.general:
          interacted = false;
          break;
        case RoomType.weapon:
          if (state.shipStatus.character.hasWeapon)
          {
            interacted = false;
            state.addOutputData(text: "\nYou already have a weapon!", color: CharacterColor.red);
          }
          else
          {
            state.shipStatus.character.hasWeapon = true;
            state.addOutputData(text: "\nPicked up weapon!", color: CharacterColor.green);
          }
          break;
        case RoomType.heal1:
          if (state.shipStatus.character.hp == Character.maxHP)
          {
            interacted = false;
            state.addOutputData(text: "\nYou already have max HP!", color: CharacterColor.red);
          }
          else
          {
            state.shipStatus.character.hp++;
          }
          break;
        case RoomType.heal2:
          if (state.shipStatus.character.hp == Character.maxHP)
          {
            interacted = false;
            state.addOutputData(text: "\nYou already have max HP!", color: CharacterColor.red);
          }
          else
          {
            state.shipStatus.character.hp = min(state.shipStatus.character.hp, Character.maxHP);
          }
          break;
        case RoomType.reveal3:
          final List<Room> unrevealedRooms = state.shipStatus.getUnrevealedRooms();
          if (unrevealedRooms.isEmpty)
          {
            interacted = false;
            state.addOutputData(text: "\nAll rooms are already revealed!", color: CharacterColor.red);
          }
          else
          {
            final Random rand = Random();
            List<Room> revealedRooms = [];
            final int revealCount = 3;
            while (unrevealedRooms.isNotEmpty && revealedRooms.length < revealCount)
            {
              final rRoom = unrevealedRooms.removeAt(rand.nextInt(unrevealedRooms.length));
              rRoom.isDetected = true;
              revealedRooms.add(rRoom);
            }
            state.addOutputData(text: "\nRevealed the following room(s):", color: CharacterColor.green);
            for (final Room r in revealedRooms)
            {
              state.addOutputData(text: "\n${r.name}", color: CharacterColor.purple);
            }
          }
          break;
        case RoomType.escape:
          if (!state.shipStatus.character.hasItem)
          {
            interacted = false;
            state.addOutputData(text: "\nYou cannot escape without your target item!", color: CharacterColor.red);
          }
          else
          {
            print("WINNING");
            state.win();
          }
          break;
        case RoomType.randomItem:
          //TODO
          state.addOutputData(text: "\nNOTHING HAPPENED...", color: CharacterColor.yellow);
          break;
      }

      if (interacted)
      {
        charRoom.hasInteraction = false;
        state.shipStatus.updateShipData(2);
        showStatus(state);
        state.checkHealth();
      }
    }
    else
    {
      state.addOutputData(text: "\nNothing to interact with!", color: CharacterColor.red);
    }
  }

  static void showStatus(final ConsoleDataState state, {String args = ""})
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
    CharacterColor healthColor = CharacterColor.green;
    if (state.shipStatus.character.hp.toDouble() / Character.maxHP.toDouble() < 0.4)
    {
      healthColor = CharacterColor.red;
    }
    else if (state.shipStatus.character.hp.toDouble() / Character.maxHP.toDouble() < 0.8)
    {
      healthColor = CharacterColor.yellow;
    }

    final weaponColor = state.shipStatus.character.hasWeapon ? CharacterColor.green : CharacterColor.yellow;
    final itemColor = state.shipStatus.character.hasItem ? CharacterColor.green : CharacterColor.yellow;
    state.addOutputData(text: "\nHEALTH: ", color: CharacterColor.normal, singleCharacterMode: false);
    state.addOutputData(text: "${state.shipStatus.character.hp}/${Character.maxHP}", color: healthColor, singleCharacterMode: false);
    state.addOutputData(text: "\nWEAPON: ", color: CharacterColor.normal, singleCharacterMode: false);
    state.addOutputData(text: state.shipStatus.character.hasWeapon ? "EQUIPPED" : "[NONE]", color: weaponColor, singleCharacterMode: false);
    state.addOutputData(text: "\nITEM: ", color: CharacterColor.normal, singleCharacterMode: false);
    state.addOutputData(text: "${state.shipStatus.character.hasItem ? "COLLECTED" : "[NOT FOUND]"}\n", color: itemColor, singleCharacterMode: false);
  }

  static void move(final ConsoleDataState state, {required String args})
  {
    if (args.isNotEmpty)
    {
      final Room? r = state.shipStatus.getRoomByName(roomName: args);
      if (r != null)
      {
        final List<Room> allNeighborRooms = state.shipStatus.getNeighbouringRooms(state.shipStatus.character.currentRoom, false);
        final List<Room> openNeighborRooms = state.shipStatus.getNeighbouringRooms(state.shipStatus.character.currentRoom, true);
        if (allNeighborRooms.contains(r))
        {
          if (openNeighborRooms.contains(r))
          {
            state.addOutputData(text: "\nMoved to room ", color: CharacterColor.normal);
            state.addOutputData(text: "${r.name}\n", color: CharacterColor.purple);
            state.shipStatus.character.currentRoom = r;
            state.shipStatus.updateShipData(1);
            showStatus(state);
            state.checkHealth();
          }
          else
          {
            state.addOutputData(text: "\nDoor to room ", color: CharacterColor.red);
            state.addOutputData(text: r.name, color: CharacterColor.purple);
            state.addOutputData(text: " is locked!", color: CharacterColor.red);
          }
        }
        else
        {
          state.addOutputData(text: "\nCannot reach ", color: CharacterColor.red);
          state.addOutputData(text: "${r.name}\n", color: CharacterColor.purple);
        }
      }
      else
      {
        state.addOutputData(text: "\nCould not find room ", color: CharacterColor.red);
        state.addOutputData(text: "$args\n", color: CharacterColor.purple);
      }
    }
    else
    {
      state.addOutputData(text: "\nPlease specify the room to move to!\n", color: CharacterColor.red);
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
    state.addOutputData(text: "\nWelcome to the Mothership Communication System (MCS) v6.2\n", color: CharacterColor.green);
    state.addOutputData(text: "\nEnter your command. Type ", color: CharacterColor.normal);
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