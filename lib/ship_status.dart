
import 'package:flutter/material.dart';
import 'package:rpg_terminal/console_data_state.dart';

class Point2D
{
  int x;
  int y;
  Point2D({required this.x, required this.y});
}

class Room
{
  final String name;
  final Point2D position;
  bool hasEnergy;
  bool hasOxygen;

  Room({
    required this.name,
    required this.position,
    this.hasEnergy = false,
    this.hasOxygen = false,
  });
}

class AirLock
{
  final String name;
  final Room? room1;
  final Room? room2;
  bool isOpen;
  bool isVertical;
  final Point2D lockPos;
  final Point2D labelPos;
  final int length;

  AirLock({
    required this.name,
    required this.room1,
    required this.room2,
    required this.isOpen,
    required this.isVertical,
    required this.lockPos,
    required this.labelPos}) : length = isVertical ? 2 : 4;
}


class ShipStatus
{
  final List<Room> rooms;
  final List<AirLock> locks;
  static final List<List<TextSpan>> _pureShipData = _getShip();
  final List<List<TextSpan>> _shipData = [];

  factory ShipStatus.defaultLayout()
  {
    final Room crew = Room(name: "  CREW  \nQUARTERS", position: Point2D(x: 8, y: 3), hasOxygen: true);
    final Room bridge = Room(name: " MAIN \nBRIDGE", position: Point2D(x: 11, y: 11));
    final Room cafe = Room(name: "CAFE &\nGALLEY", position: Point2D(x: 9, y: 19));
    final Room corridor = Room(name: "C\nO\nR\nR\nI\nD\nO\nR", position: Point2D(x: 35, y: 8));
    final Room storage = Room(name: "STORAGE", position: Point2D(x: 44, y: 10));
    final Room cpu = Room(name: "CPU", position: Point2D(x: 45, y: 15), hasEnergy: true, hasOxygen: true);
    final Room engine = Room(name: "E\nN\nG\nI\nN\nE", position: Point2D(x: 57, y: 9));
    final List<Room> rooms = [crew, bridge, cafe, corridor, storage, cpu, engine];

    final List<AirLock> locks =
    [
      AirLock(name: "LK01", room1: crew, room2: bridge, isOpen: false, isVertical: false, lockPos: Point2D(x: 10, y: 7), labelPos: Point2D(x: 10, y: 8)),
      AirLock(name: "LK02", room1: cafe, room2: bridge, isOpen: true, isVertical: false, lockPos: Point2D(x: 10, y: 16), labelPos: Point2D(x: 10, y: 17)),
      AirLock(name: "LK\n03", room1: corridor, room2: bridge, isOpen: true, isVertical: true, lockPos: Point2D(x: 22, y: 11), labelPos: Point2D(x: 23, y: 11)),
      AirLock(name: "LK\n04", room1: corridor, room2: storage, isOpen: true, isVertical: true, lockPos: Point2D(x: 38, y: 11), labelPos: Point2D(x: 39, y: 11)),
      AirLock(name: "LK\n05", room1: storage, room2: engine, isOpen: true, isVertical: true, lockPos: Point2D(x: 54, y: 8), labelPos: Point2D(x: 52, y: 8)),
      AirLock(name: "LK06", room1: storage, room2: cpu, isOpen: false, isVertical: false, lockPos: Point2D(x: 50, y: 13), labelPos: Point2D(x: 50, y: 14)),
      AirLock(name: "LK07", room1: storage, room2: null, isOpen: true, isVertical: false, lockPos: Point2D(x: 45, y: 6), labelPos: Point2D(x: 45, y: 7)),
    ];

    return ShipStatus(rooms: rooms, locks: locks);
  }

  ShipStatus({
    required this.rooms,
    required this.locks,
  })
  {
    updateShipData();
  }

  void updateShipData()
  {
    _shipData.clear();
    for (final List<TextSpan> line in _pureShipData)
    {
      List<TextSpan> newLine = [];
      newLine.addAll(line);
      _shipData.add(newLine);
    }

    //rooms
    for (final Room room in rooms)
    {
      TextStyle roomStyle;
      if (room.hasEnergy && room.hasOxygen)
      {
        roomStyle = ConsoleDataState.getTextStyle(CharacterColor.green);
      }
      else if (room.hasEnergy && !room.hasOxygen)
      {
        roomStyle = ConsoleDataState.getTextStyle(CharacterColor.yellow);
      }
      else if (!room.hasEnergy && room.hasOxygen)
      {
        roomStyle = ConsoleDataState.getTextStyle(CharacterColor.blue);
      }
      else //if (!room.hasEnergy && !room.hasOxygen)
      {
        roomStyle = ConsoleDataState.getTextStyle(CharacterColor.red);
      }


      final Point2D curPos = Point2D(x: room.position.x, y: room.position.y);
      for (final String char in room.name.characters)
      {
        if (char == "\n")
        {
          curPos.y++;
          curPos.x = room.position.x;
        }
        else
        {
          _shipData[curPos.y][curPos.x] = TextSpan(text: char, style: roomStyle);
          curPos.x++;
        }
      }
    }

    //locks
    for (final AirLock lock in locks)
    {
      final Point2D curLabelPos = Point2D(x: lock.labelPos.x, y: lock.labelPos.y);
      for (final String char in lock.name.characters)
      {
        if (char == "\n")
        {
          curLabelPos.y++;
          curLabelPos.x = lock.labelPos.x;
        }
        else
        {
          _shipData[curLabelPos.y][curLabelPos.x] = TextSpan(text: char, style: ConsoleDataState.getTextStyle(CharacterColor.gray));
          curLabelPos.x++;
        }
      }

      final Point2D curLockPos = Point2D(x: lock.lockPos.x, y: lock.lockPos.y);
      final String horizontalChar = lock.isOpen ? "." : "_";
      final String verticalChar = lock.isOpen ? ":" : "|";
      for (int i = 0; i < lock.length; i++)
      {
         _shipData[curLockPos.y][curLockPos.x] = TextSpan(text: lock.isVertical ? verticalChar : horizontalChar, style: ConsoleDataState.getTextStyle(CharacterColor.orange));
         if (lock.isVertical)
         {
            curLockPos.y++;
         }
         else
         {
            curLockPos.x++;
         }
      }
    }
  }

  List<List<TextSpan>> getShipData()
  {
    return _shipData;
  }

  static List<List<TextSpan>> _getShip()
  {
    //LINE 0
    final List<TextSpan> line0 = [];
    line0.addAll(_getTextSpan("                    ______ _____ __    _____ _____ ______ ______", ConsoleDataState.getTextStyle(CharacterColor.purple)));

    //LINE 1
    final List<TextSpan> line1 = [];
    line1.addAll(_getTextSpan("        .~~~~~~,      ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
    line1.addAll(_getTextSpan("||   ||__  ||    ||__  ||___   ||   ||  ||", ConsoleDataState.getTextStyle(CharacterColor.purple)));

    //LINE 2
    final List<TextSpan> line2 = [];
    line2.addAll(_getTextSpan(r"      //        \     ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
    line2.addAll(_getTextSpan("||   ||___ ||___ ||___ ___||   ||   ||__||", ConsoleDataState.getTextStyle(CharacterColor.purple)));

    //LINE 3
    final List<TextSpan> line3 = [];
    line3.addAll(_getTextSpan(r"     ||          |  ", ConsoleDataState.getTextStyle(CharacterColor.normal)));
    line3.addAll(_getTextSpan("SIGMA CLASS LIGHT FREIGHTER - DAEDALUS CORP.", ConsoleDataState.getTextStyle(CharacterColor.orange)));

    //LINE 4
    final List<TextSpan> line4 = [];
    line4.addAll(_getTextSpan(r"     ||          |                                        _     ", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 5
    final List<TextSpan> line5 = [];
    line5.addAll(_getTextSpan(r"      \\        /                            /    /      / | /| ", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 6
    final List<TextSpan> line6 = [];
    line6.addAll(_getTextSpan(r"       \\      /                   _________/    /______/  |< | ", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 7
    final List<TextSpan> line7 = [];
    line7.addAll(_getTextSpan(r"   _____\\    /              _____/   |               |    | \| ", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 8
    final List<TextSpan> line8 = [];
    line8.addAll(_getTextSpan(r"  /__/__//    \______       /____/    |                    |    ", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 9
    final List<TextSpan> line9 = [];
    line9.addAll(_getTextSpan(r"    //         ######\\    /____/     |                    |  /|", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 10
    final List<TextSpan> line10 = [];
    line10.addAll(_getTextSpan(r"   //  (             #\\_______/      |               |    | / <", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 11
    final List<TextSpan> line11 = [];
    line11.addAll(_getTextSpan(r"  <|  ( O                                             |    |/  <", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 12
    final List<TextSpan> line12 = [];
    line12.addAll(_getTextSpan(r"  <|  ( O                ______                       |    |\  <", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 13
    final List<TextSpan> line13 = [];
    line13.addAll(_getTextSpan(r"   \\  (             #//   ____\      |__________|    |    | \ <", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 14
    final List<TextSpan> line14 = [];
    line14.addAll(_getTextSpan(r"  __\\__       ######//    \____\     |#         |    |    |  \|", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 15
    final List<TextSpan> line15 = [];
    line15.addAll(_getTextSpan(r"  \__\__\\    /             \____\    |#              |    |    ", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 16
    final List<TextSpan> line16 = [];
    line16.addAll(_getTextSpan(r"        //    \                   \___|#____      ____|_   | /| ", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 17
    final List<TextSpan> line17 = [];
    line17.addAll(_getTextSpan(r"       //      \                            \    \      \  |< | ", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 18
    final List<TextSpan> line18 = [];
    line18.addAll(_getTextSpan(r"      //        \                            \____\      \_| \| ", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 19
    final List<TextSpan> line19 = [];
    line19.addAll(_getTextSpan(r"     ||          |                                              ", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 20
    final List<TextSpan> line20 = [];
    line20.addAll(_getTextSpan(r"     ||          |                                  ,,,,,,,,,,,,", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 21
    final List<TextSpan> line21 = [];
    line21.addAll(_getTextSpan(r"      \\        /                                   : TOP VIEW :", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    //LINE 22
    final List<TextSpan> line22 = [];
    line22.addAll(_getTextSpan(r"        `~~~~~~´                                    ‘‘‘‘‘‘‘‘‘‘‘‘", ConsoleDataState.getTextStyle(CharacterColor.normal)));

    List<List<TextSpan>> shipData = [
      line0,
      line1,
      line2,
      line3,
      line4,
      line5,
      line6,
      line7,
      line8,
      line9,
      line10,
      line11,
      line12,
      line13,
      line14,
      line15,
      line16,
      line17,
      line18,
      line19,
      line20,
      line21,
      line22
    ];

    return shipData;

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




}