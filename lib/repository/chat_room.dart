import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mysql_client/exception.dart';
import 'package:sqflite/sqflite.dart';
import 'package:moyubie/utils/tidb.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:path/path.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:retry/retry.dart';

class TiDBConnection {
  MySQLConnection? connection;

  String host = "";
  int port = 0;
  String userName = "";
  String userNamePrefix = "";
  String password = "";
  String roomId = "";

  close() async {
    if (connection != null) {
      if (connection!.connected) {
        try {
          await connection?.close();
        } catch (e) {
          // Ignore.
        }
      }
    }
    connection = null;
  }

  bool hasSet() {
    return host.isNotEmpty &&
        port != 0 &&
        userName.isNotEmpty &&
        password.isNotEmpty;
  }

  setConnect(String host, int port, String userName, String password,
      String roomId) async {
    this.host = host;
    this.port = port;
    this.userName = userName;
    this.password = password;
    this.roomId = roomId;
    userNamePrefix = userName.split(".").first;

    close();
  }

  clearConnect() async {
    host = "";
    port = 0;
    userName = "";
    userNamePrefix = "";
    password = "";
    roomId = "";

    close();
  }

  @override
  String toString() {
    return "hose: $host, port: $port, userName: $userName, password: $password";
  }

  String toToken() {
    String connText = hasSet() //
        ? toConnectionToken(host, port, userName, password, roomId)
        : "";
    return base64.encode(utf8.encode(connText));
  }

  static TiDBConnection? fromToken(String token) {
    try {
      String str = utf8.decode(base64.decode(token));
      var conn = TiDBConnection();
      var (host, port, userName, password, roomId) =
          parseTiDBConnectionText(str);
      conn.setConnect(host, port, userName, password, roomId);
      return conn;
    } catch (e) {
      return null;
    }
  }

  Future<String?> validateRemoteDB() async {
    var dbConn =
        await ChatRoomRepository.getRemoteDb(this, true, forceInit: true);
    if (dbConn == null) {
      return "Cannot connect to remote database with ${toString()}, ";
    }
    return null;
  }
}

enum Role {
  host,
  guest,
}

class ChatRoom {
  String uuid;
  String name;
  DateTime createTime; // UTC time zone.
  String connectionToken;
  Role role;

  ChatRoom({
    required this.uuid,
    required this.name,
    required this.createTime,
    required this.connectionToken,
    required this.role,
  });

  bool isHost() {
    return role == Role.host;
  }

  Map<String, dynamic> toSQLMap() {
    return {
      'uuid': uuid,
      'name': name,
      'create_time': createTime.toIso8601String(),
      'connection': connectionToken,
      'role': role.name,
    };
  }
}

enum MessageSource {
  user,
  bot,
}

// The context
class AIConversationContext {
  // TODO
}

class Message {
  String uuid;
  String userName;
  DateTime createTime; // UTC time zone.
  String message;
  MessageSource source;
  bool ask_ai = false;

  Message(
      {required this.uuid,
      required this.userName,
      required this.createTime,
      required this.message,
      required this.source,
      this.ask_ai = false});

  Map<String, dynamic> toSQLMap() {
    return {
      'uuid': uuid,
      'user_name': userName,
      'create_time': createTime.toIso8601String(),
      'message': message,
      'source': source.name,
      'ask_ai': ask_ai ? '1' : '0',
    };
  }

  @override
  String toString() {
    return 'Message{uuid: $uuid, userName: $userName, createTime: $createTime, message: $message, source: $source}, askAI: $ask_ai';
  }
}

class ChatRoomRepository {
  static const String _tableChatRoom = 'chat_room';
  static const String _columnChatRoomUuid = 'uuid';
  static const String _columnChatRoomName = 'name';
  // UTC time zone. SQLite: Text, TiDB: DateTime
  static const String _columnChatRoomCreateTime = 'create_time';
  static const String _columnChatRoomConnectionToken = 'connection';
  // The user role of this chat room, could be 'host' or 'guest'
  static const String _columnChatRoomRole = 'role';

  static const String _columnMessageUuid = 'uuid';
  static const String _columnMessageUserName = 'user_name';
  // UTC time zone. SQLite: Text, TiDB: DateTime
  static const String _columnMessageCreateTime = 'create_time';
  static const String _columnMessageMessage = 'message';
  static const String _columnMessageSource = 'source';
  static const String _columnAskAI = 'ask_ai';

  static const RetryOptions _connectRetry =
      RetryOptions(delayFactor: Duration(milliseconds: 500), maxAttempts: 5);
  static const RetryOptions _queryRetry =
      RetryOptions(delayFactor: Duration(milliseconds: 200), maxAttempts: 4);
  static const RetryOptions _longRetry =
      RetryOptions(delayFactor: Duration(milliseconds: 500), maxAttempts: 4);

  static var myTiDBConn = TiDBConnection();
  // TODO: We haven't implement connection GC yet!!!
  static var connMap = <String, TiDBConnection>{};

  static Database? _database;
  static ChatRoomRepository? _instance;

  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  ChatRoomRepository._internal();

  factory ChatRoomRepository() {
    _instance ??= ChatRoomRepository._internal();
    return _instance!;
  }

  Future<Database> _getDb() async {
    if (_database == null) {
      final String path = join(await getDatabasesPath(), 'moyubie.db');
      _database = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        print("on create!");
        await db.execute('''
          CREATE TABLE $_tableChatRoom (
            $_columnChatRoomUuid VARCHAR(36) PRIMARY KEY,
            $_columnChatRoomName TEXT,
            $_columnChatRoomCreateTime TEXT,
            $_columnChatRoomConnectionToken TEXT,
            $_columnChatRoomRole TEXT
          )
        ''');
      });
    }
    return _database!;
  }

  TiDBConnection ensureConnection(String token) {
    var conn = connMap[token];
    if (conn != null) {
      return conn;
    }
    conn = TiDBConnection.fromToken(token)!;
    connMap[token] = conn;
    return conn;
  }

  updateRemoteDBConfig(
    String host,
    int port,
    String userName,
    String password,
  ) {
    myTiDBConn.setConnect(host, port, userName, password, "");
  }

  static Future<String?> validateRemoteDB(TiDBConnection conn) async {
    var dbConn = await getRemoteDb(conn, true, forceInit: true);
    if (dbConn == null) {
      return "Cannot connect to remote database with ${conn.toString()}, ";
    }
    return null;
  }

  removeDatabase() async {
    String path = join(await getDatabasesPath(), 'moyubie.db');
    await deleteDatabase(path);
    _database = null;
  }

  Future<bool> removeDatabaseRemote() async {
    final db = await getRemoteDb(myTiDBConn, true);
    if (db != null) {
      var res = await _queryRetry
          .retry(() => db.execute("SHOW DATABASES LIKE 'moyubie';"));
      if (res.rows.isNotEmpty) {
        await _queryRetry.retry(() => db.execute("DROP DATABASE moyubie;"));
      }

      res = await _queryRetry.retry(() => db.execute(
          "SELECT `user` FROM mysql.user where `user` like '${myTiDBConn.userNamePrefix}.MYB_%';"));
      for (final row in res.rows) {
        final user = row.colByName("user");
        await _queryRetry.retry(() => db.execute("DROP USER '$user';"));
      }

      await myTiDBConn.close();
      return true;
    } else {
      return false;
    }
  }

  String myRemoteDBToString() {
    return "hose: ${myTiDBConn.host}, port: ${myTiDBConn.port}, userName: ${myTiDBConn.userName}, password: ${myTiDBConn.password}";
  }

  static Future<MySQLConnection?> getRemoteDb(TiDBConnection conn, bool isHost,
      {bool forceInit = false}) async {
    bool shouldInit =
        (conn.connection == null || !conn.connection!.connected || forceInit) &&
            conn.hasSet();

    try {
      if (shouldInit) {
        // Make sure the old connection has been close
        conn.close();

        var dbConn = await MySQLConnection.createConnection(
            host: conn.host,
            port: conn.port,
            userName: conn.userName,
            password: conn.password);
        conn.connection = dbConn;

        await _connectRetry.retry(() => dbConn.connect());

        dbConn.onClose(() {
          // I haven't check the client carefully.
          // Is it enough to handle connection broken or someting bad?
          conn.connection = null;
        });

        if (isHost) {
          var res = await _queryRetry
              .retry(() => dbConn.execute("SHOW DATABASES LIKE 'moyubie';"));
          if (res.rows.isEmpty) {
            FirebaseAnalytics.instance.logEvent(name: "remote_createdb");
            await _queryRetry.retry(
                () => dbConn.execute("CREATE DATABASE IF NOT EXISTS moyubie;"));
          }
          await _queryRetry.retry(() => dbConn.execute("USE moyubie;"));
          res = await _queryRetry
              .retry(() => dbConn.execute("SHOW TABLES LIKE 'chat_room';"));
          if (res.rows.isEmpty) {
            await _longRetry.retry(() => dbConn.execute('''
            CREATE TABLE IF NOT EXISTS $_tableChatRoom (
            $_columnChatRoomUuid VARCHAR(36) PRIMARY KEY,
            $_columnChatRoomName TEXT,
            $_columnChatRoomCreateTime DATETIME(6),
            $_columnChatRoomConnectionToken TEXT,
            $_columnChatRoomRole TEXT
            )
            '''));
          }
        }
      }
    } catch (e) {
      return Future(() => null);
    }

    return conn.connection;
  }

  Future<List<ChatRoom>> getChatRooms({String? roomId}) async {
    final db = await _getDb();
    String? where = roomId == null ? null : "$_columnChatRoomUuid = '$roomId'";
    final List<Map<String, dynamic>> maps =
        await db.query(_tableChatRoom, where: where);
    return List.generate(maps.length, (i) {
      var ct = maps[i][_columnChatRoomCreateTime];
      return ChatRoom(
          uuid: maps[i][_columnChatRoomUuid],
          name: maps[i][_columnChatRoomName],
          createTime: DateTime.parse(ct),
          connectionToken: maps[i][_columnChatRoomConnectionToken],
          role: Role.values
              .firstWhere((e) => e.name == maps[i][_columnChatRoomRole]));
    });
  }

  Future<List<ChatRoom>> getChatRoomsRemote() async {
    try {
      final db = await getRemoteDb(myTiDBConn, true);
      if (db == null) return Future(() => []);
      var res = await _longRetry
          .retry(() => db.execute("SELECT * FROM moyubie.$_tableChatRoom;"));
      return res.rows.map((e) {
        var maps = e.assoc();
        return ChatRoom(
          uuid: maps[_columnChatRoomUuid]!,
          name: maps[_columnChatRoomName]!,

          createTime: DateTime.parse("${maps[_columnChatRoomCreateTime]!}Z"), //
          connectionToken: maps[_columnChatRoomConnectionToken]!,
          role: Role.values
              .firstWhere((e) => e.name == maps[_columnChatRoomRole]),
        );
      }).toList();
    } catch (e) {
      return Future(() => []);
    }
  }

  Future<void> upsertLocalChatRooms(List<ChatRoom> rooms) async {
    final db = await _getDb();
    // await db.execute("DELETE FROM $_tableChatRoom;");
    for (var room in rooms) {
      // TODO Remote this
      await db.execute('''
        CREATE TABLE IF NOT EXISTS `msg_${room.uuid}` (
          $_columnMessageUuid VARCHAR(36) PRIMARY KEY,
          $_columnMessageUserName TEXT,
          $_columnMessageCreateTime TEXT,
          $_columnMessageMessage TEXT,
          $_columnMessageSource TEXT,
          $_columnAskAI INTEGER
        )
        ''');
      await db.insert(
        _tableChatRoom,
        room.toSQLMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  String genRandomString(int length) {
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  // return: (isExists, Room)
  Future<(bool, ChatRoom?)> joinChatRoom(String connToken) async {
    var roomConn = TiDBConnection.fromToken(connToken);
    if (roomConn == null) {
      return Future(() => (false, null));
    }

    final room = ChatRoom(
        uuid: roomConn.roomId,
        name: "Other Chat Room",
        createTime: DateTime.now().toUtc(),
        connectionToken: connToken,
        role: Role.guest);

    final rooms = await getChatRooms(roomId: room.uuid);
    if (rooms.isNotEmpty) {
      return (true, rooms.first);
    }

    await addChatRoom(room);

    return (false, room);
  }

  Future<void> addChatRoom(ChatRoom room) async {
    var roomConn = TiDBConnection.fromToken(room.connectionToken)!;
    final remoteDB = await getRemoteDb(myTiDBConn, true);
    if (remoteDB != null) {
      if (room.isHost()) {
        String user = "${myTiDBConn.userNamePrefix}.MYB_${genRandomString(10)}";
        String pwd = genRandomString(20);
        String msgTable = "msg_${room.uuid}";

        await _longRetry.retry(() => remoteDB.execute('''
        CREATE TABLE IF NOT EXISTS moyubie.`$msgTable` (
          $_columnMessageUuid VARCHAR(36) PRIMARY KEY,
          $_columnMessageUserName TEXT,
          $_columnMessageCreateTime DATETIME(6),
          $_columnMessageMessage TEXT,
          $_columnMessageSource TEXT,
          $_columnAskAI INTEGER
        );
        '''));

        await _longRetry.retry(() => remoteDB.execute('''
        BEGIN;
        CREATE USER '$user'@'%' IDENTIFIED BY '$pwd';
        GRANT INSERT, SELECT on `moyubie`.`$msgTable` TO '$user'@'%';
        COMMIT;
        '''));

        // Update the connection to use the new user.
        roomConn.setConnect(
            myTiDBConn.host, myTiDBConn.port, user, pwd, room.uuid);
        // Looks like TiDB Serverless need some time to prepare the new users' connection.
        // And immediate connection will fail.
      }

      await _longRetry.retry(() => remoteDB.execute(
            '''
        INSERT IGNORE INTO moyubie.$_tableChatRoom 
        (`$_columnChatRoomUuid`, `$_columnChatRoomName`, `$_columnChatRoomCreateTime`, `$_columnChatRoomConnectionToken`, `$_columnChatRoomRole`) VALUES 
        ('${room.uuid}', :name, '${room.createTime.toString()}', :token, '${room.role.name}');
        ''',
            {
              "name": room.name,
              "token": roomConn.toToken(),
            },
          ));
    }

    // Use the user who is dedicated for this chat room to chat
    room.connectionToken = roomConn.toToken();

    final db = await _getDb();
    await db.insert(
      _tableChatRoom,
      room.toSQLMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.execute('''
        CREATE TABLE IF NOT EXISTS `msg_${room.uuid}` (
          $_columnMessageUuid VARCHAR(36) PRIMARY KEY,
          $_columnMessageUserName TEXT,
          $_columnMessageCreateTime INTEGER,
          $_columnMessageMessage TEXT,
          $_columnMessageSource TEXT,
          $_columnAskAI INTEGER
        )
        ''');
  }

  Future<void> updateChatRoom(ChatRoom chatRoom) async {
    final db = await _getDb();
    await db.update(
      _tableChatRoom,
      chatRoom.toSQLMap(),
      where: '$_columnChatRoomUuid = ?',
      whereArgs: [chatRoom.uuid],
    );

    if (chatRoom.isHost()) {
      final remoteDB = await getRemoteDb(myTiDBConn, true);
      if (remoteDB != null) {
        await _longRetry.retry(() => remoteDB.execute('''
        UPDATE moyubie.$_tableChatRoom SET
        $_columnChatRoomName = :name,
        $_columnChatRoomCreateTime = '${chatRoom.createTime.toString()}',
        $_columnChatRoomConnectionToken = :token
        WHERE $_columnChatRoomUuid = '${chatRoom.uuid}'
        ''', {"name": chatRoom.name, "token": chatRoom.connectionToken}));
      }
    }
  }

  Future<void> deleteChatRoom(ChatRoom room) async {
    final uuid = room.uuid;
    final db = await _getDb();
    await db.transaction((txn) async {
      await txn.delete(
        _tableChatRoom,
        where: '$_columnChatRoomUuid = ?',
        whereArgs: [uuid],
      );
    });
    await db.execute('DROP TABLE IF EXISTS `msg_$uuid`');

    final conn = TiDBConnection.fromToken(room.connectionToken)!;

    if (conn.hasSet() && room.isHost()) {
      final remoteDB = await getRemoteDb(myTiDBConn, true);
      if (remoteDB != null) {
        await _longRetry.retry(() => remoteDB.execute(
            "DELETE FROM moyubie.$_tableChatRoom WHERE $_columnChatRoomUuid = '$uuid'"));
        await _queryRetry.retry(
            () => remoteDB.execute("DROP TABLE IF EXISTS moyubie.`msg_$uuid`"));
        // Do some protection, in case bug cause the root user removed.
        if (!(conn.userName.split(".").length == 2 &&
            conn.userName.split(".")[1] == "root")) {
          await _queryRetry.retry(
              () => remoteDB.execute("DROP USER IF EXISTS '${conn.userName}'"));
        }
      }
    }
  }

  Future<List<Message>> getMessagesByChatRoomUUid(ChatRoom room,
      {int limit = 500}) async {
    final db = await _getDb();
    final List<Map<String, dynamic>> maps = await db.query(
      '`msg_${room.uuid}`',
      orderBy: "julianday($_columnMessageCreateTime) desc",
      limit: limit,
    );
    return List<Message>.from(maps.reversed.map((m) => Message(
        uuid: m[_columnMessageUuid],
        userName: m[_columnMessageUserName],
        createTime: DateTime.parse(m[_columnMessageCreateTime]),
        message: m[_columnMessageMessage],
        source: MessageSource.values
            .firstWhere((e) => e.name == m[_columnMessageSource]),
        ask_ai: m[_columnAskAI] == 1)));
  }

  Future<List<Message>> getNewMessagesByChatRoomUuidRemote(
      ChatRoom room, DateTime? from,
      {int limit = 500}) async {
    final conn = ensureConnection(room.connectionToken);
    final db =
        await getRemoteDb(conn, false /* isHost should always be false */);
    if (db == null) {
      return Future(() => []);
    }
    String whereClause = "";
    if (from != null) {
      whereClause = "WHERE $_columnMessageCreateTime > '${from.toString()}'";
    }
    var res;
    var sql;
    try {
      sql =
          "SELECT * FROM moyubie.`msg_${room.uuid}` $whereClause ORDER BY $_columnMessageCreateTime desc limit $limit;";
      res = await _longRetry.retry(() => db.execute(sql));
    } catch (e) {
      print("catch error: $sql, error: ${e.toString()}");
      return Future(() => []);
    }
    var list = List<Message>.from(res.rows.map((e) {
      var maps = e.assoc();
      return Message(
        uuid: maps[_columnMessageUuid]!,
        userName: maps[_columnMessageUserName]!,
        createTime: DateTime.parse(
            "${maps[_columnMessageCreateTime]!}Z"), // Add a Z at the end to tell the parser that it is a utc DateTime
        message: maps[_columnMessageMessage]!,
        source: MessageSource.values
            .firstWhere((e) => e.name == maps[_columnMessageSource]!),
        ask_ai: maps[_columnAskAI] == "1",
      );
    }).toList());
    return list.reversed.toList();
  }

  Future<void> addMessage(ChatRoom room, List<Message> messages) async {
    await addMessageLocal(room, messages);

    // Don't wait for remote message finish adding to TiDB.
    addMessageRemote(room, messages);
  }

  Future<void> addMessageLocal(ChatRoom room, List<Message> messages) async {
    final db = await _getDb();
    final batch = db.batch();
    for (final m in messages) {
      batch.insert('`msg_${room.uuid}`', m.toSQLMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    batch.commit();
  }

  Future<String?> addMessageRemote(
      ChatRoom room, List<Message> messages) async {
    try {
      await _insertMessageRemote(room, messages);
    } catch (e) {
      if (e is MySQLServerException) {
        if (e.errorCode == 1146) {
          // Create the chat room. It is possible that user create chat room before adding mysql/TiDB connection.
          final rooms = await getChatRooms(roomId: room.uuid);
          if (rooms.length == 1) {
            // Add chat room again.
            final newRoom = rooms.first;
            await addChatRoom(newRoom);
            await _insertMessageRemote(newRoom, messages);
          } else {
            // If it is not, then too weird. I give up!
          }
        }
      }

      return e.toString();
    }

    FirebaseAnalytics.instance.logEvent(name: "remote_saved_msg");

    // Lots of exception we haven't handled yet. But who cares!
    return null;
  }

  Future<void> _insertMessageRemote(
      ChatRoom room, List<Message> messages) async {
    final conn = ensureConnection(room.connectionToken);
    final remoteDB = await getRemoteDb(conn, false);
    if (remoteDB != null) {
      // Must use SQL with param
      // TODO This mysql client does not support batch?
      for (final m in messages) {
        await _longRetry.retry(() =>
            remoteDB.execute('''INSERT IGNORE INTO moyubie.`msg_${room.uuid}` 
      ($_columnMessageUuid, $_columnMessageUserName, $_columnMessageCreateTime, $_columnMessageMessage, $_columnMessageSource, $_columnAskAI) VALUES 
      (:uuid, :user, :createTime, :message, :source, :askAI)''', {
              "uuid": m.uuid,
              "user": m.userName,
              "createTime": m.createTime.toString(),
              "message": m.message,
              "source": m.source.name,
              "askAI": m.ask_ai ? 1 : 0
            }));
      }
    }
  }
}
