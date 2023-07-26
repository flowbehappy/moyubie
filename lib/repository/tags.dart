import 'dart:developer';

import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:moyubie/controller/settings.dart';
import 'package:moyubie/utils/tidb.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:stream_transform/stream_transform.dart';

class _CachedConnection {
  MySQLConnection? _last;

  _CachedConnection(Stream<MySQLConnection> stream) {
    stream.listen((event) {
      if (_last != null && _last != event) {
        log("Update connection. [old=$_last, new=$event]", name: "moyubie::_CachedConnection");
        _last!.close();
      }
      _last = event;
    },
        onError: (err) =>
            log("ERROR [$err]", name: "moyubie::_CachedConnection"),
        onDone: () => log("APP CLOSED", name: "moyubie::_CachedConnection"),
        cancelOnError: false);
  }

  MySQLConnection? get value => _last;
}

class TagsRepository {
  factory TagsRepository.byConfig(SettingsController ctl,
      {bool forceInit = false}) {
    final stream = ctl.serverlessCmd.stream.switchMap((p0) {
      final (host, port, user, password) = parseTiDBConnectionText(p0);
      if (host.isEmpty || port == 0 || user.isEmpty) {
        return Stream<MySQLConnection>.error(Exception("Invalid DB"));
      }
      return Stream.fromFuture(() async {
        final conn = await MySQLConnection.createConnection(
            host: host, port: port, userName: user, password: password);
        await conn.connect();
        await prepareTables(conn);
        return conn;
      }());
    });
    return TagsRepository(_CachedConnection(stream));
  }

  final _CachedConnection _conn;

  TagsRepository(this._conn);

  static const _tagName = "name";
  static const _tagAddedAt = "added_at";
  static const _table = "tags";
  static const _db = "moyubie";

  static Future<void> prepareTables(MySQLConnection conn) async {
    await conn.execute("CREATE DATABASE IF NOT EXISTS $_db");
    await conn.execute("CREATE TABLE  IF NOT EXISTS `$_db`.$_table("
        "$_tagName TEXT,"
        "$_tagAddedAt DATETIME,"
        "INDEX sand_of_time(added_at)"
        ");");
  }

  Future<void> addNewTags(List<String> tags) async {
    final now = DateTime.now();
    if (_conn.value == null) {
      throw Exception("The connection isn't ready for now...");
    }
    final insert = await _conn.value!.prepare(
        "INSERT INTO $_db.$_table($_tagName, $_tagAddedAt) VALUES (?, ?);");
    await Future.wait(tags.map((e) => insert.execute([e, now])),
        eagerError: true);
  }

  Future<List<String>> fetchMostPopularTags(int limit) async {
    if (_conn.value == null) {
      throw Exception("The connection isn't ready for now...");
    }
    final res = await _conn.value!.execute(
        "SELECT t1.NAME AS $_tagName FROM "
        "(SELECT COUNT($_tagName) AS CNT, $_tagName AS NAME FROM $_db.$_table GROUP BY $_tagName) AS t1"
        " ORDER BY t1.CNT LIMIT :limit; ",
        {"limit": limit});
    final output = <String>[];
    for (final rs in res) {
      for (final row in rs.rows) {
        output.add(row.colByName(_tagName) as String);
      }
    }
    return output;
  }
}
