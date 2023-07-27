import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:moyubie/components/news.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:moyubie/utils/tidb.dart';
import 'package:moyubie/repository/chat_room.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:stream_transform/stream_transform.dart';

class Tag {
  String name;
  DateTime time;

  Tag({
    required this.name,
    required this.time,
  });

  Map<String, dynamic> toSQLMap() {
    return {
      'name': name,
      'added_at': time.toIso8601String(),
    };
  }
}

// TODO refactor TagsRepository and ChatRoomRepository
class TagsRepository {
  static const tableTags = "tags";
  static const columnTagsName = "name";

  // UTC time zone. SQLite: Text, TiDB: DateTime
  static const columnTagsAddedAt = "added_at";

  static const String _tablePromotes = "promotes";
  static const String _columnPromotedTime = "time";
  static const String _columnPromotedNewsContent = "content";

  static const String _tableStatistics = "statistics";
  static const String _columnStatisticsKey = "key";
  static const String _columnStatisticsValue = "value";

  Future<void> addNewTags(List<String> tags) async {
    var now = DateTime.now().toUtc();
    return await _addNewTags(tags.map((n) => Tag(name: n, time: now)).toList());
  }

  // Note that we don't wait for database operations
  Future<void> _addNewTags(List<Tag> tags) async {
    final db = ChatRoomRepository().getLocalDb();
    db.then((db_) async {
      final batch = db_.batch();
      for (final tag in tags) {
        db_.insert(
          tableTags,
          tag.toSQLMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit();
    });

    final remoteDB = ChatRoomRepository().getMyRemoteDb();
    remoteDB.then((remoteDB_) async {
      if (remoteDB_ == null) {
        return;
      }

      for (final tag in tags) {
        await remoteDB_.execute(
            "INSERT IGNORE INTO moyubie.`$tableTags` VALUES (:name, :time)",
            {"name": tag.name, "time": tag.time.toString()});
      }
    });
  }

  Future<List<String>> fetchMostPopularTags(int limit,
      {bool waitSync = false}) async {
    // Firt return what we have in local
    final db = await ChatRoomRepository().getLocalDb();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t1.NAME AS $columnTagsName FROM
        (SELECT COUNT($columnTagsName) AS CNT, $columnTagsName AS NAME FROM $tableTags GROUP BY $columnTagsName) AS t1
        ORDER BY t1.CNT DESC LIMIT $limit; 
        ''');

    final localTags = maps.map((e) {
      String tag_ = e[columnTagsName];
      return tag_;
    }).toList();

    // Then start async task to synchronize remote to local
    final remoteDB = ChatRoomRepository().getMyRemoteDb();
    final fut = remoteDB.then((remoteDB_) async {
      if (remoteDB_ == null) {
        return;
      }
      final List<Map<String, dynamic>> maps = await db.query(tableTags,
          orderBy: "$columnTagsAddedAt DESC", limit: 1);
      DateTime? last;
      if (maps.isNotEmpty) {
        last = DateTime.parse(maps.first[columnTagsAddedAt]);
      }
      var sql = last == null
          ? "SELECT * FROM moyubie.`$tableTags` ORDER BY `$columnTagsAddedAt` DESC LIMIT 100"
          : "SELECT * FROM moyubie.`$tableTags` WHERE `$columnTagsAddedAt` > '${last.toString()}' ORDER BY `$columnTagsAddedAt` DESC LIMIT 100";
      final res = await remoteDB_.execute(sql);
      if (res.rows.isEmpty) {
        return;
      }
      final remoteTags = res.rows.map((e) {
        var map = e.assoc();
        return Tag(
            name: map[columnTagsName]!,
            time: DateTime.parse(map[columnTagsAddedAt]!));
      }).toList();

      await _addNewTags(remoteTags);
    });

    if (waitSync) {
      await fut;
      return fetchMostPopularTags(limit);
    }

    return localTags;
  }

  Future<void> savePromoted(PromotedRecord p) async {
    final db = await ChatRoomRepository().getLocalDb();
    final b = db.batch();
    b.insert(_tablePromotes, {
      _columnPromotedTime: p.at.toUtc().toString(),
      _columnPromotedNewsContent: JsonEncoder().convert(p.records),
    });
    await b.commit();
  }

  Future<List<PromotedRecord>> fetchPromoted() async {
    final db = await ChatRoomRepository().getLocalDb();
    final cursor =
        await db.query(_tablePromotes, orderBy: "$_columnPromotedTime DESC");
    log("Fetching from SQLite: $cursor", name: "TagsRepository");

    return cursor.map((e) {
      final items = e[_columnPromotedNewsContent] as String;
      final time = e[_columnPromotedTime] as String;
      final utime = DateTime.parse(time);
      final promotes = const JsonDecoder()
          .convert(items)
          .map<Promoted>((e) => Promoted.fromJson(e))
          .toList();
      return PromotedRecord(utime, promotes);
    }).toList(growable: false);
  }
}
