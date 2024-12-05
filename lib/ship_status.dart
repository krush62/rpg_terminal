
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mcs/console_data_state.dart';

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
  Room currentRoom;
  static const drawingChar = "☼";

  Entity({
    required this.currentRoom,
  });
}



class ShipStatus
{
  final List<List<Room>> rooms;
  final Room targetRoom;
  final Character character;
  final List<Entity> entities;
  final List<List<TextSpan>> _shipData = [];
  static const int roomHeight = 5;
  static const int horizontalLockWidth = 3;
  static const int verticalLockHeight = 1;
  static const String letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  final int width;
  final int height;
  int apCounter = 0;

  factory ShipStatus.fromLayoutData(String layoutData)
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

    //CREATE MISSION
    final Room targetRoom = getFarAwayRoom(r: character!.currentRoom, width: width, height: height, rooms: rooms);

    //CREATE ENTITY
    final Entity e = Entity(currentRoom: getFarAwayRoom(r: character.currentRoom, width: width, height: height, rooms: rooms));
    entities.add(e);

    print("TARGET ROOM: ${targetRoom.name}");
    print("ENTITY ROOM: ${e.currentRoom.name}");

    if (errorMessage.isNotEmpty)
    {
      //_showErrorDialog(context, "ERROR during level creation", errorMessage);
    }

    return ShipStatus(rooms: rooms, character: character, entities: entities, width: width, height: height, targetRoom: targetRoom);

  }

  static Room getFarAwayRoom({required final Room r, required final int width, required final int height, required final List<List<Room>> rooms})
  {
    int cx, cy;
    (cx, cy) = getRoomPositionStatic(r: r, width: width, height: height, rooms: rooms);
    final int minFinds = 15;
    int finds = 0;
    Room? foundRoom = null;
    int foundDistance = 0;
    final Random rand = Random();
    while (finds < minFinds)
    {
      final int rx = rand.nextInt(width);
      final int ry = rand.nextInt(height);
      final Room randomRoom = rooms[ry][rx];
      if (randomRoom.roomType != RoomType.noRoom)
      {
        final int distance = (rx-cx).abs() + (ry-cy).abs();
        if (foundRoom == null || distance > foundDistance)
        {
          foundRoom = randomRoom;
          foundDistance = distance;
        }
        finds++;
      }
    }
    return foundRoom!;
  }

  ShipStatus({
    required this.rooms,
    required this.character,
    required this.entities,
    required this.width,
    required this.height,
    required this.targetRoom
  })
  {
    updateShipData(0);
  }

  (int x, int y) getRoomPosition(Room r)
  {
    return getRoomPositionStatic(r: r, width: width, height: height, rooms: rooms);
  }

  static (int x, int y) getRoomPositionStatic({required final Room r, required final int width, required final int height, required final List<List<Room>> rooms})
  {
    int x = -1;
    int y = -1;
    for (int j = 0; j < height; j++)
    {
      for (int i = 0; i < width; i++)
      {
        if (rooms[j][i] == r)
        {
           return (i, j);
        }
      }
    }
    return (x, y);
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

  List<Room> getNeighbouringRooms(final Room r, bool mustBeOpen)
  {
    final List<Room> neighborRooms = [];

    final List<Room> currentRow = rooms.where((row) => row.contains(r)).first;
    final int currentRowIndex = rooms.indexOf(currentRow);
    final int currentRoomIndex = currentRow.indexOf(r);

    if (r.airLockLeft != null && currentRoomIndex > 0 && rooms[currentRowIndex][currentRoomIndex - 1].airLockRight != null && rooms[currentRowIndex][currentRoomIndex - 1].airLockRight == r.airLockLeft && (!mustBeOpen || r.airLockLeft!.isOpen))
    {
      neighborRooms.add(rooms[currentRowIndex][currentRoomIndex - 1]);
    }
    if (r.airLockRight != null && currentRoomIndex < rooms[currentRowIndex].length - 1 && rooms[currentRowIndex][currentRoomIndex + 1].airLockLeft != null && rooms[currentRowIndex][currentRoomIndex + 1].airLockLeft == r.airLockRight && (!mustBeOpen || r.airLockRight!.isOpen))
    {
      neighborRooms.add(rooms[currentRowIndex][currentRoomIndex + 1]);
    }
    if (r.airLockTop != null && currentRowIndex > 0 && rooms[currentRowIndex - 1].length > currentRoomIndex && rooms[currentRowIndex - 1][currentRoomIndex].airLockBottom != null && rooms[currentRowIndex - 1][currentRoomIndex].airLockBottom == r.airLockTop && (!mustBeOpen || r.airLockTop!.isOpen))
    {
      neighborRooms.add(rooms[currentRowIndex - 1][currentRoomIndex]);
    }
    if (r.airLockBottom != null && currentRowIndex < rooms.length - 1  && rooms[currentRowIndex + 1].length > currentRoomIndex && rooms[currentRowIndex + 1][currentRoomIndex].airLockTop != null && rooms[currentRowIndex + 1][currentRoomIndex].airLockTop == r.airLockBottom && (!mustBeOpen || r.airLockBottom!.isOpen))
    {
      neighborRooms.add(rooms[currentRowIndex + 1][currentRoomIndex]);
    }
    return neighborRooms;
  }

  Room? getRoomByName({required final String roomName, final bool useIndexOnly = false})
  {
    final String upperName = roomName.toUpperCase();
    if (!useIndexOnly)
    {
      //DIRECTION BASED
      if (upperName == "UP" || upperName == "DOWN" || upperName == "LEFT" || upperName == "RIGHT" ||
          upperName == "U" || upperName == "D" || upperName == "L" || upperName == "R" ||
          upperName == "NORTH" || upperName == "SOUTH" || upperName == "EAST" || upperName == "WEST" ||
          upperName == "N" || upperName == "S" || upperName == "E" || upperName == "W")
      {
        int cx, cy;
        (cx, cy) = getRoomPosition(character.currentRoom);
        int tx = cx;
        int ty = cy;
        if (upperName == "UP" || upperName == "U" || upperName == "NORTH" || upperName == "N")
        {
          ty--;
        }
        else if (upperName == "DOWN" || upperName == "D" || upperName == "SOUTH" || upperName == "S")
        {
          ty++;
        }
        else if (upperName == "LEFT" || upperName == "L" || upperName == "WEST" || upperName == "W")
        {
          tx--;
        }
        else //RIGHT
        {
          tx++;
        }
        if (tx >= 0 && tx < width && ty >= 0 && ty < height)
        {
          final Room tRoom = rooms[ty][tx];
          if (tRoom.roomType != RoomType.noRoom)
          {
            return tRoom;
          }
        }
      }
      else
      {
        //name based search
        for (final List<Room> row in rooms)
        {
          final Room? r = row.where((room) => room.name.toUpperCase() == upperName).firstOrNull;
          if (r != null)
          {
            return r;
          }
        }
      }
    }
    //index based search
    for (int i = 0; i < rooms.length; i++)
    {
      for (int j = 0; j < rooms[i].length; j++)
      {
        final String coordName = letters[j] + (i + 1).toString();
        if (coordName.toUpperCase() == upperName)
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
    final Set<Room> visibleRooms = (getNeighbouringRooms(character.currentRoom, true)..add(character.currentRoom)).toSet();
    for (final Room room in visibleRooms)
    {
      room.isDetected = true;
    }

    for (int i = 0; i < ap; i++)
    {
      apCounter++;
      if (apCounter % 2 == 0)
      {
         //move entity/fight
        for (final Entity e in entities)
        {
           if (e.currentRoom != character.currentRoom)
           {
             int cx, cy;
             (cx, cy) = getRoomPosition(character.currentRoom);
             Room? moveToRoom = null;
             int dist = 0;
             final List<Room> nRooms = getNeighbouringRooms(e.currentRoom, true);
             for (final nRoom in nRooms)
             {
               int nx, ny;
               (nx, ny) = getRoomPosition(nRoom);
               final int distToChar = (nx-cx).abs() + (ny-cy).abs();
               if (moveToRoom == null || distToChar < dist)
               {
                 moveToRoom = nRoom;
                 dist = distToChar;
               }
             }
             if (moveToRoom != null)
             {
               e.currentRoom = moveToRoom;
             }
           }
        }
      }
    }

    //FIGHT
    for (final Entity e in entities)
    {
      if (e.currentRoom == character.currentRoom)
      {
        if (character.hasWeapon)
        {
          character.hasWeapon = false;
        }
        else
        {
          character.hp--;
        }
      }
    }


    //DRAW

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