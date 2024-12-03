
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rpg_terminal/console_data_state.dart';

class Point2D
{
  int x;
  int y;
  Point2D({required this.x, required this.y});
}

enum RoomType
{
  noRoom,
  general,
  weapon,
  heal1,
  heal2,
  reveal3,
  escape,
  randomItem
}

const Map<int, RoomType> intRoomMap =
{
  0: RoomType.noRoom,
  1: RoomType.general,
  2: RoomType.weapon,
  3: RoomType.heal1,
  4: RoomType.heal2,
  5: RoomType.reveal3,
  6: RoomType.escape,
  7: RoomType.randomItem
};

const Map<RoomType, String> roomInfoMap =
{
  RoomType.noRoom: "There is no room here, go somewhere else.",
  RoomType.general: "A normal room, nothing special here.",
  RoomType.weapon: "You can pick up a weapon here.",
  RoomType.heal1: "Heal 1 HP.",
  RoomType.heal2: "Heal 2 HPs.",
  RoomType.reveal3: "Reveal 3 random rooms.",
  RoomType.escape: "Your starting and finishing point for your mission.",
  RoomType.randomItem: "Pick up a random item (healing or weapon."
};

class Room
{
  final String name;
  AirLock? airLockTop;
  AirLock? airLockRight;
  AirLock? airLockLeft;
  AirLock? airLockBottom;
  final RoomType roomType;
  bool isDetected;
  bool hasInteraction;

  Room({
    required this.name,
    this.airLockTop,
    this.airLockRight,
    this.airLockLeft,
    this.airLockBottom,
    this.isDetected = false,
    this.hasInteraction = true,
    required this.roomType,
  });

  bool hasAirlock(final AirLock lock)
  {
    return (airLockTop == lock || airLockLeft == lock || airLockBottom == lock || airLockRight == lock);
  }

  bool shouldBeVisible()
  {
    return (isDetected && roomType != RoomType.noRoom);
  }
}

class AirLock
{
  bool isOpen;

  AirLock({
    required this.isOpen,
  });

}

class Character
{
  Room currentRoom;
  int hp;
  bool hasWeapon;
  bool hasItem;
  static const drawingChar = "☺";
  static const maxHP = 3;


  Character({
    required this.currentRoom,
    this.hp = Character.maxHP,
    this.hasWeapon = false,
    this.hasItem = false
  });
}

class Entity
{
  Room? currentRoom;
  static const drawingChar = "☼";

  Entity({
    this.currentRoom,
  });
}

class ShipStatus
{
  final List<List<Room>> rooms;
  final Character character;
  final List<Entity> entities;
  final List<List<TextSpan>> _shipData = [];
  static const int roomHeight = 5;
  static const int horizontalLockWidth = 3;
  static const int verticalLockHeight = 1;
  static const String letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  factory ShipStatus.defaultLayout()
  {
    //horizontal
    final AirLock a1b1 = AirLock(isOpen: false);
    final AirLock b1c1 = AirLock(isOpen: true);
    final AirLock a2b2 = AirLock(isOpen: false);
    final AirLock b2c2 = AirLock(isOpen: false);
    final AirLock a3b3 = AirLock(isOpen: true);
    final AirLock b3c3 = AirLock(isOpen: false);
    //vertical
    final AirLock a1a2 = AirLock(isOpen: true);
    final AirLock a2a3 = AirLock(isOpen: false);
    final AirLock b1b2 = AirLock(isOpen: false);
    final AirLock b2b3 = AirLock(isOpen: true);
    final AirLock c1c2 = AirLock(isOpen: false);
    final AirLock c2c3 = AirLock(isOpen: false);

    final AirLock c2Outside = AirLock(isOpen: false);
    final AirLock b3Outside = AirLock(isOpen: false);

    //row1
    final Room a1 = Room(name: "CABINS", roomType: RoomType.general, airLockRight: a1b1, airLockBottom: a1a2);
    final Room b1 = Room(name: "KITCHEN", roomType: RoomType.noRoom, airLockLeft: a1b1, airLockBottom: b1b2, airLockRight: b1c1);
    final Room c1 = Room(name: "DORM", roomType: RoomType.noRoom, airLockLeft: b1c1, airLockBottom: c1c2);
    //row2
    final Room a2 = Room(name: "BLA", roomType: RoomType.noRoom, airLockRight: a2b2, airLockBottom: a2a3, airLockTop: a1a2);
    final Room b2 = Room(name: "BBBB2", roomType: RoomType.general, airLockLeft: a2b2, airLockBottom: b2b3, airLockRight: b2c2, airLockTop: b1b2);
    final Room c2 = Room(name: "CCC2", roomType: RoomType.general, airLockLeft: b2c2, airLockBottom: c2c3, airLockTop: c1c2, airLockRight: c2Outside);
    //row3
    final Room a3 = Room(name: "AAAA3", roomType: RoomType.general, airLockRight: a3b3, airLockTop: a2a3);
    final Room b3 = Room(name: "BBBB3", roomType: RoomType.noRoom, airLockLeft: a3b3, airLockRight: b3c3, airLockTop: b2b3, airLockBottom: b3Outside);
    final Room c3 = Room(name: "CC3", roomType: RoomType.noRoom, airLockLeft: b3c3, airLockTop: c2c3);

    final List<Room> row1 = [a1, b1, c1];
    final List<Room> row2 = [a2, b2, c2];
    final List<Room> row3 = [a3, b3, c3];


    final Character character = Character(currentRoom: c2);
    final Entity entity = Entity(currentRoom: c3);
    final List<Entity> entities = [entity];

    return ShipStatus(rooms: [row1, row2, row3], character: character, entities: entities);
  }

  factory ShipStatus.fromLevelData(String fileData, BuildContext context)
  {
    final LineSplitter ls = LineSplitter();
    final List<String> fileLines = ls.convert(fileData);
    int? width;
    int? height;
    Character? character;
    final List<Entity> entities = [];
    final List<List<Room>> rooms = [];
    String errorMessage = "";

    for (final String line in fileLines)
    {
      if (!line.startsWith("#"))
      {
        final List<String> split = line.split("|");
        if (split.isNotEmpty && split[0].length == 1)
        {
          if (split[0] == "W" && split.length == 2)
          {
            width = int.tryParse(split[1]);
          }
          else if (split[0] == "H" && split.length == 2)
          {
            height = int.tryParse(split[1]);
          }
          else if (split[0] == "C" && split.length == 3 && split[1].length == 1 && letters.contains(split[1]) && int.tryParse(split[2]) != null)
          {
            if (width != null && height != null && rooms.isNotEmpty)
            {
              if (character == null)
              {
                final int colIndex = letters.indexOf(split[1]);
                final int rowIndex = int.parse(split[2]) - 1;
                if (colIndex < 0 || colIndex > width - 1 || rowIndex < 0 || rowIndex > height - 1)
                {
                  errorMessage = ("CHARACTER LOCATION OUT OF BOUNDS! ${split[1]} ${split[2]}");
                  break;
                }
                else if (rooms[rowIndex][colIndex].roomType != RoomType.noRoom)
                {
                   character = Character(currentRoom: rooms[rowIndex][colIndex]);
                }
                else
                {
                  errorMessage = ("CHARACTER MUST BE IN VALID ROOM! ${split[1]} ${split[2]}");
                  break;
                }
              }
              else
              {
                errorMessage = ("ONLY ONE CHARACTER CAN BE DEFINED!!");
                break;
              }
            }
            else
            {
              errorMessage = ("DIMENSIONS AND ROOMS MUST BE DEFINED BEFORE CHARACTER!");
              break;
            }
          }
          else if (split[0] == "E" && split.length == 3 && split[1].length == 1 && letters.contains(split[1]) && int.tryParse(split[2]) != null)
          {
            if (width != null && height != null && rooms.isNotEmpty)
            {
              final int colIndex = letters.indexOf(split[1]);
              final int rowIndex = int.parse(split[2]) - 1;
              if (colIndex < 0 || colIndex > width - 1 || rowIndex < 0 || rowIndex > height - 1)
              {
                errorMessage = ("ENTITY LOCATION OUT OF BOUNDS! ${split[1]} ${split[2]}");
                break;
              }
              else if (rooms[rowIndex][colIndex].roomType != RoomType.noRoom)
              {
                entities.add(Entity(currentRoom: rooms[rowIndex][colIndex]));
              }
              else
              {
                errorMessage = ("ENTITY MUST BE IN VALID ROOM! ${split[1]} ${split[2]}");
                break;
              }
            }
            else
            {
              errorMessage = ("DIMENSIONS AND ROOMS MUST BE DEFINED BEFORE ENTITIES!");
              break;
            }
          }
          else if (split[0] == "R" && split.length == 6 && split[2].length == 1 && letters.contains(split[2]) && int.tryParse(split[3]) != null && int.tryParse(split[4]) != null && split[5].length == 4 && int.tryParse(split[5]) != null)
          {
            if (width != null && height != null)
            {
              if (rooms.isEmpty)
              {
                for (int i = 0; i < height; i++)
                {
                  final List<Room> row = [];
                  for (int j = 0; j < width; j++)
                  {
                    row.add(Room(name: "", roomType: RoomType.noRoom));
                  }
                  rooms.add(row);
                }
              }
              final int colIndex = letters.indexOf(split[2]);
              final int rowIndex = int.parse(split[3]) - 1;

              if (colIndex < 0 || colIndex > width - 1 || rowIndex < 0 || rowIndex > height - 1)
              {
                errorMessage = "ROOM IS OUT OF BOUNDS: $line";
                break;
              }


              AirLock? airlockLeft = (split[5][0] == "1" || split[5][0] == "2") ? AirLock(isOpen: split[5][0] == "1" ? false : true) : null;
              if (colIndex > 0 && rooms[rowIndex][colIndex - 1].roomType != RoomType.noRoom)
              {
                if ((rooms[rowIndex][colIndex - 1].airLockRight != null && airlockLeft == null) ||
                    (rooms[rowIndex][colIndex - 1].airLockRight == null && airlockLeft != null) ||
                    (rooms[rowIndex][colIndex - 1].airLockRight != null && airlockLeft != null && rooms[rowIndex][colIndex - 1].airLockRight!.isOpen != airlockLeft.isOpen))
                {
                  errorMessage = ("AIRLOCK (LEFT) INCONSISTENCY DETECTED!! $line");
                   break;
                }
                else
                {
                  airlockLeft = rooms[rowIndex][colIndex - 1].airLockRight;
                }
              }

              AirLock? airlockTop = (split[5][1] == "1" || split[5][1] == "2") ? AirLock(isOpen: split[5][1] == "1" ? false : true) : null;
              if (rowIndex > 0 && rooms[rowIndex - 1][colIndex].roomType != RoomType.noRoom)
              {
                if ((rooms[rowIndex - 1][colIndex].airLockBottom != null && airlockTop == null) ||
                    (rooms[rowIndex - 1][colIndex].airLockBottom == null && airlockTop != null) ||
                    (rooms[rowIndex - 1][colIndex].airLockBottom != null && airlockTop != null && rooms[rowIndex - 1][colIndex].airLockBottom!.isOpen != airlockTop.isOpen))
                {
                  errorMessage = ("AIRLOCK (TOP) INCONSISTENCY DETECTED!! $line");
                  break;
                }
                else
                {
                  airlockTop = rooms[rowIndex - 1][colIndex].airLockBottom;
                }
              }

              AirLock? airlockRight = (split[5][2] == "1" || split[5][2] == "2") ? AirLock(isOpen: split[5][2] == "1" ? false : true) : null;
              if (colIndex < width - 1 && rooms[rowIndex][colIndex + 1].roomType != RoomType.noRoom)
              {
                if ((rooms[rowIndex][colIndex + 1].airLockLeft != null && airlockRight == null) ||
                    (rooms[rowIndex][colIndex + 1].airLockLeft == null && airlockRight != null) ||
                    (rooms[rowIndex][colIndex + 1].airLockLeft != null && airlockRight != null && rooms[rowIndex][colIndex + 1].airLockLeft!.isOpen != airlockRight.isOpen))
                {
                  errorMessage = ("AIRLOCK (RIGHT) INCONSISTENCY DETECTED!! $line");
                  break;
                }
                else
                {
                  airlockRight = rooms[rowIndex][colIndex + 1].airLockLeft;
                }
              }

              AirLock? airlockBottom = (split[5][3] == "1" || split[5][3] == "2") ? AirLock(isOpen: split[5][3] == "1" ? false : true) : null;
              if (rowIndex < height - 1 && rooms[rowIndex + 1][colIndex].roomType != RoomType.noRoom)
              {
                if ((rooms[rowIndex + 1][colIndex].airLockTop != null && airlockBottom == null) ||
                    (rooms[rowIndex + 1][colIndex].airLockTop == null && airlockBottom != null) ||
                    (rooms[rowIndex + 1][colIndex].airLockTop != null && airlockBottom != null && rooms[rowIndex + 1][colIndex].airLockTop!.isOpen != airlockBottom.isOpen))
                {
                  errorMessage = ("AIRLOCK (BOTTOM) INCONSISTENCY DETECTED!! $line");
                  break;
                }
                else
                {
                  airlockBottom = rooms[rowIndex + 1][colIndex].airLockTop;
                }
              }

              final RoomType type = intRoomMap[int.parse(split[4])] ?? RoomType.general;
              final Room room = Room(roomType: type, name: split[1], isDetected: false, airLockBottom: airlockBottom, airLockRight: airlockRight, airLockTop: airlockTop, airLockLeft: airlockLeft);
              rooms[rowIndex][colIndex] = room;

            }
            else
            {
              errorMessage = ("SPECIFY DIMENSIONS BEFORE ADDING ROOMS");
              break;
            }
          }
          else
          {
            errorMessage = ("Unknown line found: $line");
            break;
          }
        }
      }

    }
    if (character == null && errorMessage.isEmpty)
    {
      errorMessage = ("NO CHARACTER SPECIFIED!");

    }

    if (errorMessage.isNotEmpty)
    {
      _showErrorDialog(context, "ERROR during level loading", errorMessage);
    }


    return ShipStatus(rooms: rooms, character: character!, entities: entities);
  }

  factory ShipStatus.fromLayoutData(String layoutData, BuildContext context)
  {
    String errorMessage = "";
    final String roomCharacter = "o";
    final LineSplitter ls = LineSplitter();
    final List<String> fileLines = ls.convert(layoutData);
    Character? character;
    final List<Entity> entities = [];
    final List<List<Room>> rooms = [];

    //DETERMINE WIDTH
    final int width = fileLines.map((s) => s.length).reduce((a, b) => a > b ? a : b);
    final int height = fileLines.length;

    //CALCULATE ROOM COUNT
    final int roomCount = fileLines
        .map((s) => s.split('').where((c) => c == roomCharacter).length) // Count in each string
        .fold(0, (total, current) => total + current); // Sum up counts

    //CREATE LIST OF AVAILABLE ROOMS
    List<Room> availableRooms =
    [
      Room(name: "ARMORY", roomType: RoomType.weapon),
      Room(name: "CABINS1", roomType: RoomType.general, hasInteraction: false),
      Room(name: "CABINS2", roomType: RoomType.general, hasInteraction: false),
      Room(name: "CANTEEN", roomType: RoomType.heal1),
      Room(name: "COCKPIT", roomType: RoomType.reveal3),
      Room(name: "HOSPITAL", roomType: RoomType.heal2),
      Room(name: "LAB", roomType: RoomType.heal1),
      Room(name: "ESCAPE POD", roomType: RoomType.escape),
      Room(name: "STORAGE1", roomType: RoomType.randomItem),
      Room(name: "STORAGE2", roomType: RoomType.randomItem),
      Room(name: "ENGINE", roomType: RoomType.general, hasInteraction: false),
      Room(name: "HIBERNATORIUM", roomType: RoomType.general, hasInteraction: false),
      Room(name: "PRISON", roomType: RoomType.general, hasInteraction: false),
      Room(name: "GYM", roomType: RoomType.general, hasInteraction: false),
      Room(name: "SERVER ROOM", roomType: RoomType.reveal3),
      Room(name: "HANGAR", roomType: RoomType.general, hasInteraction: false),
      Room(name: "MAINTENANCE", roomType: RoomType.general, hasInteraction: false),
    ];

    final int defaultRoomCount = availableRooms.length;

    if (roomCount < availableRooms.length)
    {
      errorMessage = "NOT ENOUGH ROOMS AVAILABLE, NEED AT LEAST ${availableRooms.length} ROOMS!";
    }
    else
    {
      int corridorCounter = 1;
      for (int i = defaultRoomCount; i <= roomCount; i++)
      {
        availableRooms.add(Room(name: "CORRIDOR$corridorCounter", roomType: RoomType.general, hasInteraction: false));
        corridorCounter++;
      }
      final Random random = Random();
      //CREATE SHIP
      for (int i = 0; i < height; i++)
      {
        final List<Room> row = [];
        for (int j = 0; j < width; j++)
        {
          if (j < fileLines[i].length && fileLines[i][j] == roomCharacter)
          {
            final int roomIndex = random.nextInt(availableRooms.length);
            final Room addRoom = availableRooms.removeAt(roomIndex);
            row.add(addRoom);
            if (addRoom.roomType == RoomType.escape)
            {
              character = Character(currentRoom: addRoom);
            }
          }
          else
          {
            row.add(Room(name: "", roomType: RoomType.noRoom, hasInteraction: false));
          }
        }
        rooms.add(row);
      }

      //CREATE LOCKS
      for (int i = 0; i < height; i++)
      {
        for (int j = 0; j < width; j++)
        {
          final Room room = rooms[i][j];
          if (room.roomType != RoomType.noRoom)
          {
            if (j > 0 && rooms[i][j - 1].roomType != RoomType.noRoom)
            {
               room.airLockLeft = rooms[i][j - 1].airLockRight;
            }
            if (i > 0 && rooms[i - 1][j].roomType != RoomType.noRoom)
            {
              room.airLockTop = rooms[i - 1][j].airLockBottom;
            }
            if (j < width - 1 && rooms[i][j + 1].roomType != RoomType.noRoom)
            {
              room.airLockRight = AirLock(isOpen: true);
            }
            if (i < height - 1 && rooms[i + 1][j].roomType != RoomType.noRoom)
            {
              room.airLockBottom = AirLock(isOpen: true);
            }
          }
        }
      }
    }

    if (errorMessage.isNotEmpty)
    {
      _showErrorDialog(context, "ERROR during level creation", errorMessage);
    }

    return ShipStatus(rooms: rooms, character: character!, entities: entities);

  }

  List<Room> getUnrevealedRooms()
  {
    final List<Room> unrevealedRooms = [];
    for (final List<Room> row in rooms)
    {
      unrevealedRooms.addAll(row.where((r) => (!r.isDetected && r.roomType != RoomType.noRoom)));
    }
    return unrevealedRooms;
  }


  static Future<void> _showErrorDialog(BuildContext context, String title, String content) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(content),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('EXIT'),
              onPressed: () {
                Navigator.of(context).pop();
                exit(-1);
              },
            ),
          ],
        );
      },
    );
  }


  ShipStatus({
    required this.rooms,
    required this.character,
    required this.entities
  })
  {
    updateShipData(0);
  }

  bool hasEntityInRoom(final Room r)
  {
    for (final Entity e in entities)
    {
      if (e.currentRoom == r)
      {
        return true;
      }
    }
    return false;
  }

  List<Room> getNeighbouringRooms(bool mustBeOpen)
  {
    final List<Room> neighborRooms = [];

    final List<Room> currentRow = rooms.where((row) => row.contains(character.currentRoom)).first;
    final int currentRowIndex = rooms.indexOf(currentRow);
    final int currentRoomIndex = currentRow.indexOf(character.currentRoom);

    if (character.currentRoom.airLockLeft != null && currentRoomIndex > 0 && rooms[currentRowIndex][currentRoomIndex - 1].airLockRight != null && rooms[currentRowIndex][currentRoomIndex - 1].airLockRight == character.currentRoom.airLockLeft && (!mustBeOpen || character.currentRoom.airLockLeft!.isOpen))
    {
      neighborRooms.add(rooms[currentRowIndex][currentRoomIndex - 1]);
    }
    if (character.currentRoom.airLockRight != null && currentRoomIndex < rooms[currentRowIndex].length - 1 && rooms[currentRowIndex][currentRoomIndex + 1].airLockLeft != null && rooms[currentRowIndex][currentRoomIndex + 1].airLockLeft == character.currentRoom.airLockRight && (!mustBeOpen || character.currentRoom.airLockRight!.isOpen))
    {
      neighborRooms.add(rooms[currentRowIndex][currentRoomIndex + 1]);
    }
    if (character.currentRoom.airLockTop != null && currentRowIndex > 0 && rooms[currentRowIndex - 1].length > currentRoomIndex && rooms[currentRowIndex - 1][currentRoomIndex].airLockBottom != null && rooms[currentRowIndex - 1][currentRoomIndex].airLockBottom == character.currentRoom.airLockTop && (!mustBeOpen || character.currentRoom.airLockTop!.isOpen))
    {
      neighborRooms.add(rooms[currentRowIndex - 1][currentRoomIndex]);
    }
    if (character.currentRoom.airLockBottom != null && currentRowIndex < rooms.length - 1  && rooms[currentRowIndex + 1].length > currentRoomIndex && rooms[currentRowIndex + 1][currentRoomIndex].airLockTop != null && rooms[currentRowIndex + 1][currentRoomIndex].airLockTop == character.currentRoom.airLockBottom && (!mustBeOpen || character.currentRoom.airLockBottom!.isOpen))
    {
      neighborRooms.add(rooms[currentRowIndex + 1][currentRoomIndex]);
    }
    return neighborRooms;
  }

  Room? getRoomByName({required final String roomName, final bool useIndexOnly = false})
  {
    if (!useIndexOnly)
    {
      //name based search
      for (final List<Room> row in rooms)
      {
        final Room? r = row.where((room) => room.name.toUpperCase() == roomName.toUpperCase()).firstOrNull;
        if (r != null)
        {
          return r;
        }
      }
    }
    //index based search
    for (int i = 0; i < rooms.length; i++)
    {
      for (int j = 0; j < rooms[i].length; j++)
      {
        final String coordName = letters[j] + (i + 1).toString();
        if (coordName.toUpperCase() == roomName.toUpperCase())
        {
          return rooms[i][j];
        }
      }
    }


    return null;
  }

  void updateShipData(int ap)
  {
    _shipData.clear();

    //DETECTION
    final Set<Room> visibleRooms = (getNeighbouringRooms(true)..add(character.currentRoom)).toSet();
    for (final Room room in visibleRooms)
    {
      room.isDetected = true;
    }


   //COLUMN WIDTHS
   //DIRTY!
   final List<int> colWidths = List.filled(256, horizontalLockWidth);
    for (final List<Room> row in rooms)
    {
      for (int i = 0; i < row.length; i++)
      {
        if (row[i].roomType != RoomType.noRoom)
        {
          final int potVal = row[i].name.length + 2;
          if (potVal > colWidths[i])
          {
            colWidths[i] = potVal;
          }
        }
      }
    }


    for (final List<Room> row in rooms)
    {
      //HORIZONTAL LEGEND
      if (row == rooms.first)
      {
        final List<TextSpan> legendLine = [];
        legendLine.addAll(_getTextSpan("  ", ConsoleDataState.getTextStyle(CharacterColor.gray)));
        for (int i = 0; i < row.length; i++)
        {
          if (i != 0)
          {
            legendLine.addAll(_getTextSpan("│", ConsoleDataState.getTextStyle(CharacterColor.gray)));
          }
          else
          {
            legendLine.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.gray)));
          }
          final int availableSpace = colWidths[i] - 1;
          final int space1 = availableSpace ~/ 2;
          final int space2 = availableSpace - space1;
          legendLine.addAll(_getTextSpan(" " * space1, ConsoleDataState.getTextStyle(CharacterColor.gray)));
          legendLine.addAll(_getTextSpan(letters[i], ConsoleDataState.getTextStyle(CharacterColor.gray)));
          legendLine.addAll(_getTextSpan(" " * space2, ConsoleDataState.getTextStyle(CharacterColor.gray)));
        }
        _shipData.add(legendLine);
      }




      for (int drawingRowIndex = 0; drawingRowIndex < (roomHeight - 1); drawingRowIndex++)
      {
        final List<TextSpan> line = [];

        //VERTICAL LEGEND
        if (row != rooms.first && drawingRowIndex == 0)
        {
          line.addAll(_getTextSpan("─ ", ConsoleDataState.getTextStyle(CharacterColor.gray)));
        }
        else if (drawingRowIndex == roomHeight ~/ 2)
        {
          final int rowIndex = rooms.indexOf(row) + 1;
          line.addAll(_getTextSpan("$rowIndex ", ConsoleDataState.getTextStyle(CharacterColor.gray)));
        }
        else
        {
          line.addAll(_getTextSpan("  ", ConsoleDataState.getTextStyle(CharacterColor.gray)));
        }

        //ITERATING THROUGH THE ROOMS OF THE ROW
        for (int i = 0; i < row.length; i++)
        {
          if (drawingRowIndex == 0) //FIRST ROOM ROW
          {
            if (i == 0)
            {
              if (row[i].shouldBeVisible())
              {
                if (row == rooms.first || !rooms[rooms.indexOf(row) - 1][i].shouldBeVisible())
                {
                  line.addAll(_getTextSpan("╔", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                }
                else
                {
                  line.addAll(_getTextSpan("╠", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                }
              }
              else if (row != rooms.first && rooms[rooms.indexOf(row) - 1][i].shouldBeVisible())
              {
                line.addAll(_getTextSpan("╚", ConsoleDataState.getTextStyle(CharacterColor.normal)));
              }
              else
              {
                line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
              }
            }
            else
            {
              if (row == rooms.first)
              {
                if (!row[i].shouldBeVisible())
                {
                  if (row[i - 1].shouldBeVisible())
                  {
                    line.addAll(_getTextSpan("╗", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                  }
                  else
                  {
                    line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                  }

                }
                else
                {
                  line.addAll(_getTextSpan("╦", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                }
              }
              else //NOT FIRST ROW, NOT FIRST ROOM
              {
                if (!row[i].shouldBeVisible())
                {
                  if (row[i - 1].shouldBeVisible())
                  {
                    if (!rooms[rooms.indexOf(row) - 1][i].shouldBeVisible() && !rooms[rooms.indexOf(row) - 1][i - 1].shouldBeVisible())
                    {
                      line.addAll(_getTextSpan("╗", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                    }
                    else
                    {
                      line.addAll(_getTextSpan("╣", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                    }
                  }
                  else
                  {
                    if (!rooms[rooms.indexOf(row) - 1][i].shouldBeVisible() && rooms[rooms.indexOf(row) - 1][i - 1].shouldBeVisible())
                    {
                      line.addAll(_getTextSpan("╝", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                    }
                    else if (!rooms[rooms.indexOf(row) - 1][i - 1].shouldBeVisible() && rooms[rooms.indexOf(row) - 1][i].shouldBeVisible())
                    {
                      line.addAll(_getTextSpan("╚", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                    }
                    else if (row[i].shouldBeVisible() || rooms[rooms.indexOf(row) - 1][i].shouldBeVisible())
                    {
                      line.addAll(_getTextSpan("╩", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                    }
                    else
                    {
                      line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                    }
                  }
                }
                else
                {
                  if (row[i - 1].shouldBeVisible())
                  {
                    if (!rooms[rooms.indexOf(row) - 1][i].shouldBeVisible() && !rooms[rooms.indexOf(row) - 1][i - 1].shouldBeVisible())
                    {
                      line.addAll(_getTextSpan("╦", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                    }
                    else
                    {
                      line.addAll(_getTextSpan("╬", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                    }
                  }
                  else
                  {
                    if (!rooms[rooms.indexOf(row) - 1][i].shouldBeVisible() && !rooms[rooms.indexOf(row) - 1][i - 1].shouldBeVisible())
                    {
                      line.addAll(_getTextSpan("╔", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                    }
                    else
                    {
                      line.addAll(_getTextSpan("╠", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                    }
                  }
                }
              }
            }
            if (!row[i].shouldBeVisible() && (row == rooms.first || !rooms[rooms.indexOf(row) - 1][i].shouldBeVisible()))
            {
              line.addAll(_getTextSpan((" " * (colWidths[i])), ConsoleDataState.getTextStyle(CharacterColor.normal)));
            }
            else if (row[i].airLockTop != null)
            {
               final int wallLength1 = (colWidths[i] - horizontalLockWidth) ~/ 2;
               final int wallLength2 = (colWidths[i] - horizontalLockWidth) - wallLength1;
               line.addAll(_getTextSpan(("═" * wallLength1), ConsoleDataState.getTextStyle(CharacterColor.normal)));
               if (row[i].airLockTop!.isOpen)
               {
                 line.addAll(_getTextSpan((" " * horizontalLockWidth), ConsoleDataState.getTextStyle(CharacterColor.red)));
               }
               else
               {
                 line.addAll(_getTextSpan(("─" * horizontalLockWidth), ConsoleDataState.getTextStyle(CharacterColor.red)));
               }
               line.addAll(_getTextSpan(("═" * wallLength2), ConsoleDataState.getTextStyle(CharacterColor.normal)));
            }
            else
            {
              line.addAll(_getTextSpan(("═" * (colWidths[i])), ConsoleDataState.getTextStyle(CharacterColor.normal)));

            }

            //LAST COLUMN
            if (i == row.length - 1)
            {
              if (row == rooms.first)
              {
                if (row[i].shouldBeVisible())
                {
                  line.addAll(_getTextSpan("╗", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                }
                else
                {
                  line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                }
              }
              else
              {
                if (!rooms[rooms.indexOf(row) - 1][i].shouldBeVisible() && row[i].shouldBeVisible())
                {
                  line.addAll(_getTextSpan("╗", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                }
                else if (row[i].shouldBeVisible() && rooms[rooms.indexOf(row) - 1][i].shouldBeVisible())
                {
                  line.addAll(_getTextSpan("╣", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                }
                else if (rooms[rooms.indexOf(row) - 1][i].shouldBeVisible() && !row[i].shouldBeVisible())
                {
                  line.addAll(_getTextSpan("╝", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                }
                else
                {
                  line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
                }
              }
            }
          }
          else //NON-FIRST ROOM ROW
          {
            final int wallHeight1 = ((roomHeight - 2) - verticalLockHeight) ~/ 2;
            if (!row[i].shouldBeVisible() && (i == 0 || !row[i - 1].shouldBeVisible()))
            {
              line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.red)));
            }
            else
            {
              if (row[i].airLockLeft != null && drawingRowIndex > wallHeight1 && drawingRowIndex < (wallHeight1 + verticalLockHeight + 1))
              {
                if (row[i].airLockLeft!.isOpen)
                {
                  line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.red)));
                }
                else
                {
                  line.addAll(_getTextSpan("│", ConsoleDataState.getTextStyle(CharacterColor.red)));
                }
              }
              else
              {
                line.addAll(_getTextSpan("║", ConsoleDataState.getTextStyle(CharacterColor.normal)));
              }
            }

            if (drawingRowIndex == 1 && row[i].shouldBeVisible())
            {
              final int availableSpace = colWidths[i];
              if (row[i].name.length > availableSpace)
              {
                line.addAll(_getTextSpan(row[i].name.substring(0, availableSpace), ConsoleDataState.getTextStyle(CharacterColor.blue)));
              }
              else
              {
                final int space1 = (availableSpace - row[i].name.length) ~/ 2;
                final int space2 = (availableSpace - row[i].name.length) - space1;
                line.addAll(_getTextSpan(" " * space1, ConsoleDataState.getTextStyle(CharacterColor.gray)));
                if (visibleRooms.contains(row[i]))
                {
                  line.addAll(_getTextSpan(row[i].name, ConsoleDataState.getTextStyle(CharacterColor.normal)));
                }
                else
                {
                  line.addAll(_getTextSpan(row[i].name, ConsoleDataState.getTextStyle(CharacterColor.gray)));
                }

                line.addAll(_getTextSpan(" " * space2, ConsoleDataState.getTextStyle(CharacterColor.gray)));
              }
            }
            else if (drawingRowIndex == roomHeight - 3 && row[i] == character.currentRoom)
            {
               final int space1 = (colWidths[i] - 1) ~/ 2;
               final int space2 = (colWidths[i] - 1) - space1;
               line.addAll(_getTextSpan(" " * space1, ConsoleDataState.getTextStyle(CharacterColor.green)));
               line.addAll(_getTextSpan(Character.drawingChar, ConsoleDataState.getTextStyle(CharacterColor.green)));
               line.addAll(_getTextSpan(" " * space2, ConsoleDataState.getTextStyle(CharacterColor.green)));
            }
            else if (drawingRowIndex == roomHeight - 2 && hasEntityInRoom(row[i]) && visibleRooms.contains(row[i]))
            {
              final int space1 = (colWidths[i] - 1) ~/ 2;
              final int space2 = (colWidths[i] - 1) - space1;
              line.addAll(_getTextSpan(" " * space1, ConsoleDataState.getTextStyle(CharacterColor.purple)));
              line.addAll(_getTextSpan(Entity.drawingChar, ConsoleDataState.getTextStyle(CharacterColor.purple)));
              line.addAll(_getTextSpan(" " * space2, ConsoleDataState.getTextStyle(CharacterColor.purple)));
            }
            else
            {
              final String emptiness = " " * (colWidths[i]);
              line.addAll(_getTextSpan(emptiness, ConsoleDataState.getTextStyle(CharacterColor.normal)));
            }

            //LAST COLUMN
            if (i == row.length - 1 && row[i].shouldBeVisible())
            {
              if (row[i].airLockRight != null && drawingRowIndex > wallHeight1 && drawingRowIndex < (wallHeight1 + verticalLockHeight + 1))
              {
                if (row[i].airLockRight!.isOpen)
                {
                  line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.red)));
                }
                else
                {
                  line.addAll(_getTextSpan("│", ConsoleDataState.getTextStyle(CharacterColor.red)));
                }
              }
              else
              {
                line.addAll(_getTextSpan("║", ConsoleDataState.getTextStyle(CharacterColor.normal)));
              }
            }
          }
        }
        _shipData.add(line);
      }

      //LAST ROW (extra)
      if (row == rooms.last)
      {
        final List<TextSpan> line = [];
        line.addAll(_getTextSpan("  ", ConsoleDataState.getTextStyle(CharacterColor.gray)));
        for (int i = 0; i < row.length; i++)
        {
          if (i == 0)
          {
            if (!row[i].shouldBeVisible())
            {
              line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
            }
            else
            {
              line.addAll(_getTextSpan("╚", ConsoleDataState.getTextStyle(CharacterColor.normal)));
            }
          }
          else
          {
            if (!row[i].shouldBeVisible())
            {
              if (!row[i - 1].shouldBeVisible())
              {
                line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
              }
              else
              {
                line.addAll(_getTextSpan("╝", ConsoleDataState.getTextStyle(CharacterColor.normal)));
              }
            }
            else
            {
              if (!row[i - 1].shouldBeVisible())
              {
                line.addAll(_getTextSpan("╚", ConsoleDataState.getTextStyle(CharacterColor.normal)));
              }
              else
              {
                line.addAll(_getTextSpan("╩", ConsoleDataState.getTextStyle(CharacterColor.normal)));
              }
            }
          }

          if (!row[i].shouldBeVisible())
          {
            line.addAll(_getTextSpan((" " * (colWidths[i])), ConsoleDataState.getTextStyle(CharacterColor.normal)));
          }
          else if (row[i].airLockBottom != null)
          {
            final int wallLength1 = (colWidths[i] - horizontalLockWidth) ~/ 2;
            final int wallLength2 = (colWidths[i] - horizontalLockWidth) - wallLength1;
            line.addAll(_getTextSpan(("═" * wallLength1), ConsoleDataState.getTextStyle(CharacterColor.normal)));
            if (row[i].airLockBottom!.isOpen)
            {
              line.addAll(_getTextSpan((" " * horizontalLockWidth), ConsoleDataState.getTextStyle(CharacterColor.red)));
            }
            else
            {
              line.addAll(_getTextSpan(("─" * horizontalLockWidth), ConsoleDataState.getTextStyle(CharacterColor.red)));
            }
            line.addAll(_getTextSpan(("═" * wallLength2), ConsoleDataState.getTextStyle(CharacterColor.normal)));
          }
          else
          {
            line.addAll(_getTextSpan(("═" * (colWidths[i])), ConsoleDataState.getTextStyle(CharacterColor.normal)));
          }
          if (i == row.length - 1)
          {
            if (!row[i].shouldBeVisible())
            {
              line.addAll(_getTextSpan(" ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
            }
            else
            {
              line.addAll(_getTextSpan("╝", ConsoleDataState.getTextStyle(CharacterColor.normal)));
            }
          }
        }
        _shipData.add(line);
      }
    }
  }

  static List<TextSpan> _getTextSpan(final String text, final TextStyle style)
  {
    final List<TextSpan> spanList = [];
    for (final String char in text.characters)
    {
      spanList.add(TextSpan(text: char, style: style));
    }
    return spanList;
  }

  List<List<TextSpan>> getShipData()
  {
    return _shipData;
  }


}